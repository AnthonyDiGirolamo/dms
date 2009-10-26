class HomeController < ApplicationController

  #before_filter :handle_remember_cookie

  def index
    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @Home }
    end
  end
end
