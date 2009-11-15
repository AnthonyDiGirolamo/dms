# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  # All requests will attempt to get
  # the user’s local timezone
  prepend_before_filter :set_user_time_zone

private

#  def handle_remember_cookie
#    if logged_in? and valid_remember_cookie?
#      unless current_user.remember_token_expires_at > Time.now
#        logout_keeping_session!
#      end
#    end
#  end

  def set_user_time_zone
    Time.zone = current_user.time_zone if logged_in?
  end

  def session_expire
    if logged_in?
      if session[:expires_at].nil? or session[:expires_at] < Time.now.to_i
        logout_keeping_session!
        flash[:error] = 'Your session expired. Please, login again.'
        redirect_to login_path
      end
    end
  end

  def update_activity_time
    if logged_in?
      session[:expires_at] = 20.minutes.from_now.to_i
    end
  end

  # Find document via a users documents or shares
  # TODO: add manager/corporate override
  def find_document_by_id
    @document = current_user.documents.find_by_id(params[:id])

    if !@document.nil? # This is my document
      @my_doc = true
    else # This is not my document
      # Check for an existing share
      @share = current_user.shares_by_others.find_by_document_id(params[:id])

      if @share.nil? # I don't have access to this doc
        flash[:error] = 'That document does not exist.'
        redirect_to(documents_url)

      else # This is a document shared with me
        @document = @share.document
        @shared_doc = true
      end
    end

    # Checked out? - by who?
    if @document and @document.checked_out?
      @checked_out_by = User.find @document.checked_out_by # Get who checked it out
      @my_checkout = true if @checked_out_by == current_user # Is it me?
    end
  end

  def document_access
    # If my document
    if @document and @my_doc
      @edit_access = !@document.checked_out? or @my_checkout
      @delete_access = !@document.checked_out?
      @share_access = @checkout_access = true
    # If document shared with me
    elsif @document and @share and @shared_doc
      @edit_access = @share.can_update? and (!@document.checked_out? or @my_checkout)
      @checkout_access = @share.can_checkout?
      @delete_access = @share_access = false
    else
      # Should never get here
      @edit_access = @delete_access = @checkout_access = @share_access = false
      flash[:error] = "You don't have access to that."
      redirect_to(documents_url)
    end
  end

end

