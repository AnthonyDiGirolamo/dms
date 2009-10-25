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

  def set_user_time_zone
    Time.zone = current_user.time_zone if logged_in?
  end

  def session_expire
    if session[:expires_at].nil? or session[:expires_at] < Time.now
      logout_killing_session!
      flash[:error] = 'Your session expired. Please, login again.'
      redirect_to login_path
    end
  end

  def update_activity_time
    session[:expires_at] = 20.minutes.from_now
  end

end

