class DocumentsController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  # For pre-loading the /document/:id parameter in a URL
  before_filter :find_document_by_id, :only => [:edit, :show, :update, :destroy, :checkin, :checkout]
  # For pre-loading role and department names
  #before_filter :all_roles, :all_departments, :only => [:new, :create, :edit ]

  SEND_FILE_METHOD = :default

  def download
    head(:not_found) and return if (document = Document.find_by_id(params[:id])).nil?
    head(:forbidden) and return unless document.downloadable?(current_user)

    path = document.document.path(params[:style])
    head(:bad_request) and return unless File.exist?(path) && params[:format].to_s == File.extname(path).gsub(/^\.+/, '')

    # Use the content type set by paperclip
    send_file_options = { :type => document.document.content_type }
    # Create a title based on document.name
    file_name = ActiveSupport::Inflector::titleize(document.name).gsub(/ /, "")
    file_name = ActiveSupport::Inflector::underscore(file_name).gsub(/ /, "")
    # Use mimetype_fu to get the proper extension
    send_file_options[:filename] = file_name + "." + document.file_extension
    # Use the original extension
    #send_file_options[:filename] = file_name + File.extname(document.document.path).to_s

    case SEND_FILE_METHOD
      when :apache then send_file_options[:x_sendfile] = true
      when :nginx then head(:x_accel_redirect => path.gsub(Rails.root, ''), :content_type => send_file_options[:type]) and return
    end

    send_file(path, send_file_options)
  end

  def index
    @user = current_user
    @used_space = current_user.documents.sum(:document_file_size)
    @documents = current_user.documents
  end

  def new
    @document = current_user.documents.new
  end

  def create
    @document = current_user.documents.new(params[:document])
    if current_user.documents.sum(:document_file_size) < current_user.quota
      if @document.save
        flash[:notice] = 'Document was successfully created.'
        redirect_to(@document)
      else
        render :action => "new"
      end
    else
      flash[:error] = 'Uploading this document will exceeded your quota.'
      render :action => "index"
    end
  end

  def checkout
  end

  def checkin
  end

  def show
  end

  def edit
  end

  def update
    if @document.update_attributes(params[:document])
      flash[:notice] = 'Document was successfully updated.'
      redirect_to(@document)
    else
      render :action => "edit"
    end
  end

  def destroy
    begin
      @document.destroy
      flash[:notice] = 'Document was successfully destroyed.'
    rescue
      flash[:error] = 'Unable to destroy that document.'
    end
    redirect_to(documents_url)
  end

private

  def find_document_by_id
    @document = current_user.documents.find_by_id(params[:id])
  end
end
