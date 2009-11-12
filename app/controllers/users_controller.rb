class UsersController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time, :except => [:new, :create, :activate]
  require_role "administrator", :for_all_except => [:new, :create, :activate, :show, :edit ]

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
    role = get_role_by_name(params[:role][:name])
    department = get_department_by_name(params[:department][:name])
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
      request = UserRequest.create
      request.user_id = @user.id
      request.role_id = role.id
      request.department_id = department.id unless role.name == "administrator"
      request.save!

      redirect_back_or_default(root_path)
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
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default(root_path)
    else
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default(root_path)
    end
  end

  def suspend
    @user.suspend!
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  def show
    @time = session[:expires_at]
    @requests = UserRequest.find_all_by_user_id current_user.id, :include => [ :role, :department ], :order => 'created_at ASC'
  end

  def edit
    # allow changing name
    # what else?
    #   submit new requests
  end

  def index
    all_users
    render :action => 'all'
  end

  def all
    all_users
  end

  def pending
    users_by_state "pending"
  end

  def active
    users_by_state "active"
  end

private

  def all_roles
    @roles = Role.find :all, :order => 'name ASC'
  end

  def all_departments
    @departments = Department.find :all, :order => 'name ASC'
  end

  def get_role_by_name(name)
    Role.find_by_name name
  end

  def get_department_by_name(name)
    Department.find_by_name name
  end

  def find_user
    begin
      if user_admin?
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    rescue
      flash[:error] = 'That user does not exist.'
      redirect_back_or_default(users_path)
    end
  end

  def user_admin?
    current_user.roles.first.name == "administrator"
  end

  def all_users
    @users = User.paginate :page => params[:page], :include => [:roles, :departments], :order => 'login ASC', :per_page => 25
  end

  def users_by_state(state)
    @users = User.paginate_by_state state, :page => params[:page], :include => [:roles, :departments], :order => 'login ASC', :per_page => 25
  end

end
