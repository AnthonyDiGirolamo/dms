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

      redirect_back_or_default(root_path) ; return
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
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
    @user.suspend!
    redirect_to users_path ; return
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path ; return
  end

  def destroy
    @user.delete!
    redirect_to users_path ; return
  end

  def purge
    @user.destroy
    redirect_to users_path ; return
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
      @audits = Audit.paginate_by_user_id @user.id, :page => params[:page], :include => [:user, :share, :document], :order => sort, :per_page => 25
    end
    @used_space = current_user.documents.sum(:document_file_size)
    @requests = UserRequest.find_all_by_user_id @user.id, :include => [ :role, :department ], :order => 'created_at DESC'
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

    @users = User.paginate :page => params[:page], :include => [:roles, :departments], :order => sort, :per_page => 25

    if request.xml_http_request? 
      render :partial => "user_table", :layout => false 
    end 
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
    @users = User.paginate_by_state state, :page => params[:page], :include => [:roles, :departments], :order => 'login ASC', :per_page => 25
  end

end
