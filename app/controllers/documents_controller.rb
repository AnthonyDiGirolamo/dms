class DocumentsController < ApplicationController

  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  # For pre-loading the /document/:id parameter in a URL
  before_filter :find_document_by_id, :only => [:download, :edit, :show, :update, :destroy, :checkin, :checkout]
  before_filter :document_access, :only => [:download, :edit, :show, :update, :destroy, :checkin, :checkout]

  if RAILS_ENV == 'production'
    SEND_FILE_METHOD = :nginx
  else
    SEND_FILE_METHOD = :default
  end


  def download
    head(:not_found) and return if (document = Document.find(params[:id])).nil?
    #head(:forbidden) and return unless document.downloadable?(current_user)

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

    make_audit(document, nil, current_user, "download document, ID:'#{document.id}', Name:'#{document.name}', Size:'#{document.document_file_size}', Type:'#{document.document_content_type}', OriginalFileName:'#{document.document_file_name}'")

    case SEND_FILE_METHOD
      when :apache then send_file_options[:x_sendfile] = true
      when :nginx then head(:x_accel_redirect => path.gsub(Rails.root, ''), :content_type => send_file_options[:type], :content_disposition => "attachment; filename=#{send_file_options[:filename]}" ) and return
    end

    send_file(path, send_file_options)
  end

  def index
    @user = current_user
    @used_space = current_user.documents.sum(:document_file_size)
    @documents = current_user.documents

    if !params[:sort].nil?
      sort = case params[:sort]
        when "name" then "name ASC" 
        when "name_desc" then "name DESC" 
        #when "document_content_type" then "document_content_type ASC" 
        #when "document_content_type_desc" then "document_content_type DESC" 
        when "document_file_size" then "document_file_size ASC" 
        when "document_file_size_desc" then "document_file_size DESC" 
        when "updated_at" then "updated_at ASC" 
        when "updated_at_desc" then "updated_at DESC" 
      end
    else
      params[:sort] = "updated_at_desc"
      sort = 'updated_at DESC'  
    end
    @documents = Document.paginate_by_user_id @user.id, :page => params[:page], :order => sort, :per_page => 10
    @documents_page = true
  end

  def shared
    @user = current_user
    @used_space = current_user.documents.sum(:document_file_size)
    #@documents_shared_with_me = current_user.shared_documents_by_others
    if !params[:sort].nil?
      sort = case params[:sort]
        when "name" then "name ASC" 
        when "name_desc" then "name DESC" 
        #when "document_content_type" then "document_content_type ASC" 
        #when "document_content_type_desc" then "document_content_type DESC" 
        when "document_file_size" then "document_file_size ASC" 
        when "document_file_size_desc" then "document_file_size DESC" 
        when "updated_at" then "updated_at ASC" 
        when "updated_at_desc" then "updated_at DESC" 
      end
    else
      params[:sort] = "updated_at_desc"
      sort = 'updated_at DESC'  
    end
    @documents = Document.paginate_by_sql ['SELECT "documents".*, "shares".document_id AS id FROM "documents" INNER JOIN "shares" ON "documents".id = "shares".document_id WHERE ("shares".user_id = ? ) ORDER BY '+sort, @user.id ], :page => params[:page], :per_page => 10
    @shared_list = true
    @shared_page = true
    render :action => "index"
  end

  def department
    @user = current_user

    if current_user.has_role?("manager") or current_user.has_role?("corporate")

      return if validate_sql_integer(params[:id], 'That department does not exist.', documents_path)

      begin
        @department = Department.find(params[:id])
      rescue
        @department = nil
      end

      if @department
        if @user.has_department?(@department.name)
          @used_space = current_user.documents.sum(:document_file_size)
          #@documents = @department.documents
          if !params[:sort].nil?
            sort = case params[:sort]
              when "name" then "name ASC" 
              when "name_desc" then "name DESC" 
              #when "document_content_type" then "document_content_type ASC" 
              #when "document_content_type_desc" then "document_content_type DESC" 
              when "document_file_size" then "document_file_size ASC" 
              when "document_file_size_desc" then "document_file_size DESC" 
              when "updated_at" then "updated_at ASC" 
              when "updated_at_desc" then "updated_at DESC" 
            end
          else
            params[:sort] = "updated_at_desc"
            sort = 'updated_at DESC'  
          end
          @documents = Document.paginate_by_sql ['SELECT "documents".*, "departments".id AS department_id, "departments".name AS department_name FROM "users" INNER JOIN "departments_users" ON "departments_users".user_id = "users".id INNER JOIN "departments" on "departments_users".department_id = "departments".id INNER JOIN "documents" ON "users".id = "documents".user_id WHERE "departments".id = ? ORDER BY '+sort, params[:id] ], :page => params[:page], :per_page => 10
          @department_list = true
          @department_page = true
          render :action => "index"
        else
          flash[:error] = "You don't have access to that department."
          redirect_to documents_path ; return
        end
      else
        flash[:error] = "That department does not exist."
        redirect_to documents_path ; return
      end
    else
      flash[:error] = "You don't have access to that."
      redirect_to documents_path ; return
    end
  end

  def corporate
    @user = current_user
    if current_user.has_role?("corporate")
      @departments = current_user.departments
      @corporate_page = true
    else
      flash[:error] = "You don't have access to that."
      redirect_to documents_path ; return
    end
  end

  def new
    @document = current_user.documents.new
  end

  def create
    @document = current_user.documents.new(params[:document])
    if current_user.documents.sum(:document_file_size) < current_user.quota
      if @document.save
        make_audit(@document, nil, current_user, "create document, ID:'#{@document.id}', Name:'#{@document.name}', Size:'#{@document.document_file_size}', Type:'#{@document.document_content_type}', OriginalFileName:'#{@document.document_file_name}'")
        flash[:notice] = 'Document successfully created.'
        redirect_to(@document) ; return
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
      redirect_to(@document) ; return
    end

    if !@document.checked_out?
      @document.checked_out = true
      @document.checked_out_by = current_user
      @document.checked_out_at = Time.now

      if @document.save
        make_audit(@document, nil, current_user, "checkout document, ID:'#{@document.id}', Name:'#{@document.name}'")
        flash[:notice] = 'Successfully checked-out and locked to changes by others.'
        redirect_to(@document) ; return
      else
        flash[:error] = 'Document could not be checked-out.'
        redirect_to(@document) ; return
      end

    else
      flash[:error] = 'This document is already checked-out.'
      redirect_to(@document) ; return
    end
  end

  def checkin
    if !@checkout_access
      flash[:error] = 'You do not have access to check-in.'
      redirect_to(@document) ; return
    end

    if @document.checked_out?
      @document.checked_out = false
      @document.checked_out_by = nil
      @document.checked_out_at = nil

      if @document.save
        make_audit(@document, nil, current_user, "checkin document, ID:'#{@document.id}', Name:'#{@document.name}'")
        flash[:notice] = 'Successfully checked-in.'
        redirect_to(@document) ; return
      else
        flash[:error] = 'Document could not be checked-in.'
        redirect_to(@document) ; return
      end

    else
      flash[:error] = 'This document is already checked-in.'
      redirect_to(@document) ; return
    end
  end

  def show
    @shares = @document.shares.find :all, :include => :user

    if !@document.user.departments.empty?
      @department_name = @document.user.departments.first.name
    end
  end

  def edit
    if !@edit_access
      flash[:error] = 'You do not have access to edit.'
      redirect_to(@document) ; return
    end
  end

  def update
    if !@edit_access
      flash[:error] = 'You do not have access to update.'
      redirect_to(@document) ; return
    end

    if @document.update_attributes(params[:document])
      if params[:document][:document]
        action = "update document file"
      else
        action = "update document metadata"
      end
      make_audit(@document, nil, current_user, action+", ID:'#{@document.id}', Name:'#{@document.name}', Size:'#{@document.document_file_size}', Type:'#{@document.document_content_type}', OriginalFileName:'#{@document.document_file_name}'")
      flash[:notice] = 'Document successfully updated.'
      redirect_to(@document) ; return
    else
      flash[:error] = 'Document update failed.'
      render :action => "edit"
    end
  end

  def destroy
    if !@delete_access
      flash[:error] = 'You do not have access to delete.'
      redirect_to(@document) ; return
    end

    begin
      make_audit(nil, nil, current_user, "delete document, ID:'#{@document.id}', Name:'#{@document.name}', Size:'#{@document.document_file_size}', Type:'#{@document.document_content_type}', OriginalFileName:'#{@document.document_file_name}', Created:'#{@document.created_at}', Updated:#{@document.updated_at}'")

      for share in @document.shares
        make_audit(nil, nil, current_user, "delete document share delete cascade, ID:'#{share.id}', Owner:'#{share.owner_id}', User:'#{share.user_id}', Update?:'#{share.can_update}', Checkout?:'#{share.can_checkout}'" )
      end

      @document.shares.destroy_all
      @document.destroy
      flash[:notice] = 'Document successfully destroyed.'
      redirect_to(documents_url) ; return
    rescue
      flash[:error] = 'Unable to destroy that document.'
      redirect_to(documents_url) ; return
    end
  end

end
