class HomeController < ApplicationController
  # GET /Home
  # GET /Home.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @Home }
    end
  end
end
