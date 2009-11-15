class DocumentsController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  # For pre-loading the /document/:id parameter in a URL
  before_filter :find_document_by_id, :only => [:edit, :show, :update, :destroy, :checkin, :checkout]
  before_filter :document_access, :only => [:edit, :show, :update, :destroy, :checkin, :checkout]

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
    @documents_shared_with_me = current_user.shared_documents_by_others
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

  # RESTRICTED ACCESS BELOW

  def checkout
    if !@checkout_access
      flash[:error] = 'You do not have access to check-out.'
      redirect_to(@document)
    end

    if !@document.checked_out?
      @document.checked_out = true
      @document.checked_out_by = current_user
      @document.checked_out_at = Time.now

      if @document.save
        flash[:notice] = 'Document succesfully checked-out.'
        redirect_to(@document)
      else
        flash[:error] = 'Document could not be checked-out.'
        redirect_to(@document)
      end

    else
      flash[:error] = 'This document is already checked-out.'
      redirect_to(@document)
    end
  end

  def checkin
    if !@checkout_access
      flash[:error] = 'You do not have access to check-in.'
      redirect_to(@document)
    end

    if @document.checked_out?
      @document.checked_out = false
      @document.checked_out_by = nil
      @document.checked_out_at = nil

      if @document.save
        flash[:notice] = 'Document succesfully checked-in.'
        redirect_to(@document)
      else
        flash[:error] = 'Document could not be checked-in.'
        redirect_to(@document)
      end

    else
      flash[:error] = 'This document is already checked-in.'
      redirect_to(@document)
    end
  end

  def show
    # Get shares if any
    @shares = @document.shares.find :all, :include => :user

    # Checked out? - by who?
    if @document.checked_out?
      @checked_out_by = User.find @document.checked_out_by # Get who checked it out
      @my_checkout = true if @checked_out_by == current_user # Is it me?
    end

    # my_doc=true  =>  @document exists
    # shared_doc=true  =>  @share @document exists
    @edit_access = (@my_doc or (@shared_doc and @share.can_update?)) and !@document.checked_out? or @my_checkout
    @delete_access = @my_doc and !@document.checked_out?
    @checkout_access = @my_doc or (@shared_doc and @share.can_checkout?)
  end

  def edit
    if !@edit_access
      flash[:error] = 'You do not have access to edit.'
      redirect_to(@document)
    end

  end

  def update
    if !@edit_access
      flash[:error] = 'You do not have access to update.'
      redirect_to(@document)
    end

    if @document.update_attributes(params[:document])
      flash[:notice] = 'Document was successfully updated.'
      redirect_to(@document)
    else
      flash[:error] = 'Document update failed.'
      render :action => "edit"
    end
  end

  def destroy
    if !@delete_access
      flash[:error] = 'You do not have access to delete.'
      redirect_to(@document)
    end

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

    if @document.nil? # This is not my document

      @share = current_user.shares_by_others.find_by_document_id(params[:id])

      if @share.nil? # I don't have access to this doc
        flash[:error] = 'That document does not exist.'
        redirect_to(documents_url)

      else # This is a document shared with me
        @document = @share.document
        @shared_doc = true
        # @share.can_update?
        # @share.can_checkout?
      end

    else # This is my document
      @my_doc = true
    end
  end

  def document_access
    # my_doc=true > @document | shared_doc=true > @share & @document 
    if @document and @my_doc
      @edit_access = (@my_doc or (@shared_doc and @share.can_update?)) and !@document.checked_out? or @my_checkout
      @delete_access = @my_doc and !@document.checked_out?
      @checkout_access = @my_doc or (@shared_doc and @share.can_checkout?)
    else
      @edit_access = @delete_access = @checkout_access = false
    end
  end

end
