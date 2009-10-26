class UserRequestsController < ApplicationController

  prepend_before_filter :session_expire, :update_activity_time

  before_filter :login_required
  before_filter :find_request, :only => [:approve, :reject]
  require_role "administrator"

  def index
    @user_requests = UserRequest.paginate :page => params[:page], :include => [:role, :department, :user], :order => 'created_at ASC', :per_page => 25
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
      user.departments.delete_all
      user.departments << department
    end
    user.save!
    @user_request.state = "approved"
    @user_request.save!
    redirect_to user_requests_path
  end

  def reject
    @user_request.state = "rejected"
    @user_request.save!
    redirect_to user_requests_path
  end

private

  def find_request
    @user_request = UserRequest.find(params[:id])
  end

end
