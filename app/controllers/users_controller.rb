class UsersController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time, :except => [:new, :create, :activate]
  require_role "administrator", :for_all_except => [:new, :create, :activate, :show]

  # For pre-loading the /users/:id parameter in a URL
  before_filter :find_user, :only => [:edit, :show, :suspend, :unsuspend, :destroy, :purge]
  # For pre-loading role and department names
  before_filter :all_roles, :all_departments, :only => [:new, :create, :edit ]

  def new
    @user = User.new
  end

  def create
    logout_keeping_session!

    # check for valid role/department names
    role = Role.find_by_name(params[:role][:name])
    department = Department.find_by_name(params[:department][:name])
    if role.nil? or department.nil?
      flash[:error]  = "There was an error setting up that account.  Please try again."
      render :action => 'new'
    end

    # create user, check for validity
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      # create role/dept request
      request = UserRequest.new
      request.user_id = @user.id
      request.role_id = role.id
      request.department_id = department.id unless role.name == "administrator"
      request.save

      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
      redirect_back_or_default(root_path) ; return
    else
      flash[:error]  = "There was an error setting up that account.  Please try again."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login' ; return
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default(root_path) ; return
    else
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default(root_path) ; return
    end
  end

  def suspend
    if @user.state != "suspended" and @user.state != "deleted"
      @user.suspend!
      make_audit(nil, nil, @user, "user suspend, ID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}'")
      redirect_to users_path ; return
    else
      flash[:error] = 'That user cannot be suspended.'
      redirect_to users_path ; return
    end
  end

  def unsuspend
    if @user.state == "suspended" and @user.state != "deleted"
      @user.unsuspend!
      make_audit(nil, nil, @user, "user unsuspend, ID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}'")
      redirect_to users_path ; return
    else
      flash[:error] = 'That user cannot be unsuspended.'
      redirect_to users_path ; return
    end
  end

  def destroy
    if @user.state != "deleted"
      @user.delete!
      make_audit(nil, nil, @user, "user delete, ID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}'")
      redirect_to users_path ; return
    else
      flash[:error] = 'That user cannot be deleted.'
      redirect_to users_path ; return
    end
  end

  def purge
    if @user.state == "deleted"
      for share in @user.shares_by_me
        make_audit(nil, nil, nil, "user purge share delete cascade, UserID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}', Share ID:'#{share.id}', Owner:'#{share.owner_id}, #{share.owner.login}', User:'#{share.user_id}, #{share.user.login}', Update?:'#{share.can_update}', Checkout?:'#{share.can_checkout}'" )
        share.destroy
      end

      for share in @user.shares_by_others
        make_audit(nil, nil, nil, "user purge share delete cascade, UserID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}', Share ID:'#{share.id}', Owner:'#{share.owner_id}, #{share.owner.login}', User:'#{share.user_id}, #{share.user.login}', Update?:'#{share.can_update}', Checkout?:'#{share.can_checkout}'" )
        share.destroy
      end

      for dept in @user.departments
        make_audit(nil, nil, nil, "user purge department remove cascade, UserID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}', Department ID:'#{dept.id}', Department Name:'#{dept.name}'" )
        @user.departments.delete(dept)
      end

      for role in @user.roles
        make_audit(nil, nil, nil, "user purge role remove cascade, UserID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}', Role ID:'#{role.id}', Role Name:'#{role.name}'" )
        @user.roles.delete(role)
      end

      for doc in @user.documents
        make_audit(nil, nil, nil, "user purge document delete cascade, UserID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}', DocumentID:'#{doc.id}', Name:'#{doc.name}', Size:'#{doc.document_file_size}', Type:'#{doc.document_content_type}', OriginalFileName:'#{doc.document_file_name}', Created:'#{doc.created_at}', Updated:#{doc.updated_at}'")
        doc.destroy
      end

      make_audit(nil, nil, nil, "user purge, UserID:'#{@user.id}', Login:'#{@user.login}', Name:'#{@user.name}'")
      @user.destroy
      redirect_to users_path ; return
    else
      flash[:error] = 'That user cannot be purged, delete it first.'
      redirect_to users_path ; return
    end
  end

  def show
    if current_user.has_role?("administrator")
      @admin_access = true
      if !params[:sort].nil?
        sort = case params[:sort]
          when "action" then "action ASC" 
          when "action_desc" then "action DESC" 
          when "created_at" then "created_at ASC" 
          when "created_at_desc" then "created_at DESC" 
        end
      else
        params[:sort] = "created_at_desc"
        sort = 'created_at DESC'  
      end
      @audits = Audit.paginate_by_user_id @user.id, :page => params[:page], :include => [:user, :share, :document], :order => sort, :per_page => 10
    end
    @used_space = current_user.documents.sum(:document_file_size)
    @requests = UserRequest.find_all_by_user_id @user.id, :include => [ :role, :department ], :order => 'created_at DESC'

    @user_page = true if @user == current_user
  end

  def edit
    # TODO allow changing name, quota. what else?
  end

  def index
    if !params[:sort].nil?
      sort = case params[:sort]
        when "login" then "login ASC" 
        when "login_desc" then "login DESC" 
        when "created_at" then "created_at ASC" 
        when "created_at_desc" then "created_at DESC" 
        when "updated_at" then "updated_at ASC" 
        when "updated_at_desc" then "updated_at DESC" 
        when "state" then "state ASC" 
        when "state_desc" then "state DESC" 
        when "quota" then "quota ASC" 
        when "quota_desc" then "quota DESC" 
      end 
    else
      params[:sort] = "created_at_desc"
      sort = 'created_at DESC'  
    end

    @users = User.paginate :page => params[:page], :include => [:roles, :departments], :order => sort, :per_page => 10
    @users_page = true
  end

  def pending
    users_by_state "pending"
  end

  def active
    users_by_state "active"
  end

private

  def find_user
    if current_user.has_role?("administrator")
      return if validate_sql_integer(params[:id], 'That user does not exist.', documents_url)

      begin
        @user = User.find(params[:id])
      rescue
        flash[:error] = 'That user does not exist.'
        redirect_back_or_default(root_path) ; return
      end
    else
      @user = current_user
    end

    if @user == current_user
      @request_access = true
    end

    if @user.has_role?("corporate")
      @corporate_access = true
    elsif @user.has_role?("manager")
      @manager_access = true
    end
  end

  def users_by_state(state)
    @users = User.paginate_by_state state, :page => params[:page], :include => [:roles, :departments], :order => 'login ASC', :per_page => 10
  end

end
