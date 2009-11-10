class UserRequestsController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time

  before_filter :find_request, :only => [:approve, :reject, :revoke]
  require_role "administrator"

  def index
    @user_requests = UserRequest.paginate :page => params[:page], :include => [:role, :department, :user], :order => 'created_at ASC', :per_page => 25
  end

  # Add try/catch blocks
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

  def revoke
    user = @user_request.user
    role = @user_request.role
    department = @user_request.department
    user.roles.delete_all unless user.roles.empty?
    user.departments.delete_all unless user.departments.empty?
    user.save!
    @user_request.state = "revoked"
    @user_request.save!
    redirect_to user_requests_path
  end

private

  def find_request
    begin
      @user_request = UserRequest.find(params[:id])
    rescue
      flash[:error] = "That request does not exist."
      redirect_to user_requests_path
    end
  end

end
