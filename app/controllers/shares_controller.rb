class SharesController < ApplicationController
  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  before_filter :find_document_by_id
  before_filter :find_share_by_id, :only => [ :show, :edit, :update, :destroy, :toggle_update, :toggle_checkout ]

  def index
    redirect_to(document_path(@document))
  end

  def new
    @share = @document.shares.new
    @share.owner_id = current_user.id
  end

  def create
    @share = @document.shares.new(params[:share]) unless params[:share].nil?
    if @share and @share.save
      flash[:notice] = 'Share was successfully created.'
      redirect_to(document_path(@document))
    else
      if @share.nil?
        redirect_to(new_document_share_path(@document))
      else
        render :action => "new"
      end
    end
  end

  def show
    redirect_to(document_path(@document))
  end

  def edit
  end

  def update
    if @share.update_attributes(params[:share])
      flash[:notice] = 'Share was successfully updated.'
      redirect_to(document_path(@document))
    else
      flash[:error] = 'Share update failed.'
      render :action => "edit"
      #redirect_to(edit_document_share_path(@document, @share))
    end
  end

  def destroy
    @share.destroy
    redirect_to(document_path(@document))
  end

  def toggle_update
    if @share.can_update?
      @share.can_update = false
      @share.can_checkout = false
    else
      @share.can_update = true
    end

    if @share.save
      flash[:notice] = 'Share was successfully updated.'
      redirect_to(document_path(@document))
    else
      flash[:error] = 'Share update failed.'
      redirect_to(document_path(@document))
    end
  end

  def toggle_checkout
    if @share.can_checkout?
      @share.can_checkout = false
    else
      @share.can_checkout = true
      @share.can_update = true
    end

    if @share.save
      flash[:notice] = 'Share was successfully updated.'
      redirect_to(document_path(@document))
    else
      flash[:error] = 'Share update failed.'
      redirect_to(document_path(@document))
    end
  end

private

  def find_document_by_id
    @document = current_user.documents.find_by_id(params[:document_id])
  end

  def find_share_by_id
    begin
      @share = @document.shares.find(params[:id])
    rescue
      flash[:error] = "That does not exist."
      redirect_back_or_default(documents_path)
    end
  end

end
