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

end

