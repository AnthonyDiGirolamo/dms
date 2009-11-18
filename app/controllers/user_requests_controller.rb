class UserRequestsController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time

  require_role "administrator", :for_all_except => [:new, :create]

  before_filter :find_request, :only => [:approve, :reject, :revoke]
  before_filter :all_roles, :all_departments, :only => [:new, :create]

  def index
    if !params[:sort].nil?
      sort = case params[:sort]
        when "state" then "state ASC" 
        when "state_desc" then "state DESC" 
        when "created_at" then "created_at ASC" 
        when "created_at_desc" then "created_at DESC" 
      end
    else
      params[:sort] = "created_at_desc"
      sort = 'created_at DESC'  
    end
    @user_requests = UserRequest.paginate :page => params[:page], :include => [:role, :department, :user], :order => sort, :per_page => 25
  end

  def approve
    user = @user_request.user
    role = @user_request.role
    department = @user_request.department

    if not role.nil?
      user.roles.delete_all
      user.roles << role
    end
    if not department.nil?
      if role.name == "corporate" and current_user.has_role?("corporate")
        # Append to current departments
        user.departments << department
      else
        user.departments.delete_all
        user.departments << department
      end
    end

    @user_request.state = "approved"
    if @user_request.save and user.save
      flash[:notice] = "Request approved successfully."
      redirect_to user_requests_path ; return
    else
      flash[:error] = "Request approve failed."
      redirect_to user_requests_path ; return
    end
  end

  def reject
    @user_request.state = "rejected"
    if @user_request.save
      flash[:notice] = "Request rejected successfully."
      redirect_to user_requests_path ; return
    else
      flash[:error] = "Request reject failed."
      redirect_to user_requests_path ; return
    end
  end

  def revoke
    user = @user_request.user
    role = @user_request.role
    department = @user_request.department
    user.roles.delete_all unless user.roles.empty?
    user.departments.delete_all unless user.departments.empty?
    @user_request.state = "revoked"
    if @user_request.save and user.save
      flash[:notice] = "Request revoked successfully."
      redirect_to user_requests_path ; return
    else
      flash[:error] = "Request revoke failed."
      redirect_to user_requests_path ; return
    end
  end

  def new
  end

  def create
    # check for valid role/department names
    role = Role.find_by_name(params[:role][:name])
    department = Department.find_by_name(params[:department][:name])
    if role.nil? or department.nil?
      flash[:error]  = "There was an error processing that request. Please try again."
      render :action => 'new'
    end

    if current_user.roles.empty? or current_user.departments.empty?
      current_user.user_requests.destroy_all
    end

    @user_request = UserRequest.new
    @user_request.user_id = current_user.id      
    @user_request.role_id = role.id
    @user_request.department_id = department.id unless role.name == "administrator"

    if @user_request.save
      flash[:notice] = "Request submitted successfully."
      redirect_to root_path ; return
    else
      flash[:error]  = "There was an error processing that request. Please try again."
      render :action => 'new'
    end
  end

private

  def find_request
    begin
      @user_request = UserRequest.find(params[:id])
    rescue
      flash[:error] = "That request does not exist."
      redirect_to user_requests_path ; return
    end
  end

end
