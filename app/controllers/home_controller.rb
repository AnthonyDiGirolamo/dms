class HomeController < ApplicationController
  # GET /Home
  def index
    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @Home }
    end
  end
end
