class AuditsController < ApplicationController
  def index

    sort = case params['sort']
      when "username" then "username" 
      when "username_reverse" then "username DESC" 
      when "last_name" then "last_name" 
      when "last_name_reverse" then "last_name DESC" 
      when "updated_at" then "updated_at" 
      when "updated_at_reverse" then "updated_at DESC" 
      when "last_login" then "last_login" 
      when "last_login_reverse" then "last_login DESC" 
      when "super_user" then "super_user" 
      when "super_user_reverse" then "super_user DESC" 
    end 

    @audits = Audit.all
    @audits = User.paginate :page => params[:page], :include => [:roles, :departments], :order => sort, :per_page => 25
  end

end
