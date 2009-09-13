class HomeController < ApplicationController
  # GET /Home
  # GET /Home.xml
  def index
  	if logged_in?
	  @user = current_user
	end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @Home }
    end
  end
end
