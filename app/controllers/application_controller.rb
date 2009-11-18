# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  # All requests will attempt to get
  # the user’s local timezone
  prepend_before_filter :set_user_time_zone

private

  def all_roles
    @roles = Role.find :all, :order => 'name ASC'
  end

  def all_departments
    @departments = Department.find :all, :order => 'name ASC'
  end

#  def handle_remember_cookie
#    if logged_in? and valid_remember_cookie?
#      unless current_user.remember_token_expires_at > Time.now
#        logout_keeping_session!
#      end
#    end
#  end

  def set_user_time_zone
    Time.zone = current_user.time_zone if logged_in?
  end

  def session_expire
    if logged_in?
      if session[:expires_at].nil? or session[:expires_at] < Time.now.to_i
        logout_keeping_session!
        flash[:error] = 'Your session expired. Please, login again.'
        redirect_to login_path ; return
      end
    end
  end

  def update_activity_time
    if logged_in?
      session[:expires_at] = 20.minutes.from_now.to_i
    end
  end

  # Find document via a users documents,
  # shares, or manager/corporate access
  def find_document_by_id
    if current_user.has_role?("administrator")
      flash[:error] = "You don't have acces to that."
      redirect_to root_path ; return
    end

    @employee_access = true

    return if validate_sql_integer(params[:id], 'That document does not exist.', documents_url)

    begin
      @document = current_user.documents.find(params[:id])
    rescue
      @document = nil
    end

    if !@document.nil? # This is my document
      @my_doc = true

    else # This is not my document

      # Check for an existing share
      @share = current_user.shares_by_others.find_by_document_id(params[:id])

      if !@share.nil? # This is a document shared with me
        @document = @share.document
        @shared_doc = true

      else # This isn't a doc I have access to via shares

        # check for department access

        if current_user.has_role?("manager")
          begin
            @document = Document.find(params[:id])
          rescue
            @document = nil
          end

          if @document
            @department = @document.user.departments.first
            #@role = @document.user.roles.first
            if current_user.has_department?(@department.name) #and @role.name != "manager" and @role.name != "corporate"
              @my_doc = true # treat manager access as if you own it
              @manager_access = true
            end
          end
          if @document.nil? or @my_doc.nil?
            flash[:error] = 'That document does not exist.'
            redirect_to(documents_url) ; return
          end
        end

        if current_user.has_role?("corporate")
          begin
            @document = Document.find(params[:id])
          rescue
            @document = nil
          end

          if @document
            @department = @document.user.departments.first
            #@role = @document.user.roles.first
            if current_user.has_department?(@department.name) #and @role.name != "manager" and @role.name != "corporate"
              @my_doc = true # treat corporate access as if you own it
              @corporate_access = true
            end
          end
          if @document.nil? or @my_doc.nil?
            flash[:error] = 'That document does not exist.'
            redirect_to(documents_url) ; return
          end
        end

        if @document.nil?
          flash[:error] = 'That document does not exist.'
          redirect_to(documents_url) ; return
        end
      end

    end

    # Checked out? - by who?
    if @document and @document.checked_out?
      @checked_out_by = User.find @document.checked_out_by # Get who checked it out
      if @checked_out_by == current_user # Is it me?
        @my_checkout = true
      end
    end
  end

  # Apply permissions
  def document_access
    # If my document
    if @document and @my_doc
      if @my_checkout
        @edit_access = true
      else
        @edit_access = !@document.checked_out?
      end
      @delete_access = !@document.checked_out?
      @share_access = @checkout_access = true
    # If document shared with me
    elsif @document and @share and @shared_doc
      @edit_access = @share.can_update? and (!@document.checked_out? or @my_checkout)
      @checkout_access = @share.can_checkout?
      @delete_access = @share_access = false
    else
      # Should never get here
      @edit_access = @delete_access = @checkout_access = @share_access = false
      flash[:error] = "You don't have access to that."
      redirect_to(documents_url) ; return
    end
  end

  def find_document_share
    return if validate_sql_integer(params[:documents_id], 'That document does not exist.', documents_url)

    begin
      @document = current_user.documents.find(params[:document_id])
    rescue
      @document = nil
    end

    if @document
      @share_access = @my_doc = true
    else

      # MANAGER
      if current_user.has_role?("manager")
        begin
          @document = Document.find(params[:document_id])
        rescue
          @document = nil
        end

        if @document
          @department = @document.user.departments.first
          if current_user.has_department?(@department.name)
            # treat manager access as if you own it
            @share_access = @my_doc = true
            @manager_access = true
          end
        end
        if @document.nil? or @my_doc.nil?
          flash[:error] = "You cannot manage sharing for that document."
          redirect_to(documents_url) ; return
        end

      # CORPORATE
      elsif current_user.has_role?("corporate")
        begin
          @document = Document.find(params[:document_id])
        rescue
          @document = nil
        end

        if @document
          @department = @document.user.departments.first
          if current_user.has_department?(@department.name)
            # treat corporate access as if you own it
            @share_access = @my_doc = true
            @corporate_access = true
          end
        end
        if @document.nil? or @my_doc.nil?
          flash[:error] = "You cannot manage sharing for that document."
          redirect_to(documents_url) ; return
        end

      # NO ACCESS
      else
        @share_access = false
        @shared_doc = true
        flash[:error] = "You cannot manage sharing for that document."
        redirect_back_or_default(documents_path) ; return
      end

    end
  end

  def find_share_by_id
    return if validate_sql_integer(params[:id], 'That share does not exist.', documents_url)

    begin
      @share = @document.shares.find(params[:id])
    rescue
      flash[:error] = "That share does not exist."
      redirect_back_or_default(documents_path) ; return
    end

    if @share.nil?
      flash[:error] = "That share does not exist."
      redirect_back_or_default(documents_path) ; return
    end
  end

  def make_audit(doc, share, user, action)
    audit = Audit.new
    audit.document = doc unless doc.nil?
    audit.share = share unless doc.nil?
    audit.user = user unless user.nil?
    audit.action = action
    if not audit.save
      logger.warn "Failed Audit for Doc:#{doc} Share:#{share} User:#{user} Action:'#{action}'"
    end
  end

  def validate_sql_integer(id, error, path)
    match_data = id.match("[0-9]*")
    if match_data.size != 1 or match_data.to_s != id
      flash[:error] = error
      redirect_to(path)
      return true
    elsif id.to_i > 2147483647 or id.to_i < 0
      flash[:error] = error
      redirect_to(path)
      return true
    end
    return false
  end

end

