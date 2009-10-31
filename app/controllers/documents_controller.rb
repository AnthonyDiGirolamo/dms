class DocumentsController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  # For pre-loading the /users/:id parameter in a URL
  #before_filter :find_user, :only => [:edit, :show, :suspend, :unsuspend, :destroy, :purge]
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

  def show
    @document = current_user.documents.find_by_id(params[:id])
  end

  def new
    @document = current_user.documents.new
  end

  def edit
    @document = current_user.documents.find_by_id(params[:id])
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

  def update
    @document = current_user.documents.find_by_id(params[:id])

    if @document.update_attributes(params[:document])
      flash[:notice] = 'Document was successfully updated.'
      redirect_to(@document)
    else
      render :action => "edit"
    end
  end

  def destroy
    @document = current_user.documents.find_by_id(params[:id])
    @document.destroy

    redirect_to(documents_url)
  end

end
