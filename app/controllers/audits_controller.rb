class AuditsController < ApplicationController
  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role "administrator"

  def index
    if params[:sort].nil?
      params[:sort] = "created_at_desc"
      sort = 'created_at DESC'  
    else
      sort = case params[:sort]
        when "action" then "action ASC" 
        when "action_desc" then "action DESC" 
        when "created_at" then "created_at ASC" 
        when "created_at_desc" then "created_at DESC" 
      end
    end
    @audits = Audit.paginate :page => params[:page], :include => [:user, :share, :document], :order => sort, :per_page => 25
  end

end
