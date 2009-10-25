class UserRequestsController < ApplicationController
  before_filter :login_required
  before_filter :find_request, :only => [:approve, :reject]
  #require_role "administrator"

  def index
    @user_requests = UserRequest.paginate :page => params[:page], :include => [:role, :department, :user], :order => 'created_at ASC', :per_page => 25
  end

  def approve

  end

  def reject
      
  end

private

  def find_request
    @user_request = UserRequest.find(params[:id])
  end

end
