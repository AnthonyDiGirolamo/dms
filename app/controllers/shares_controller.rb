class SharesController < ApplicationController
  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  before_filter :find_document_by_id
  before_filter :find_share_by_id, :only => [ :show, :edit, :update, :destroy ]

  def index
    #if request.post?
      redirect_to(document_path(@document))
    #else
      #redirect_back_or_default(document_path(@document))
    #end
  end

  def new
    @share = @document.shares.new
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
  end

  def edit
  end

  def update
    @share.can_read = params[:share][:can_read]
    @share.can_update = params[:share][:can_update]
    @share.can_checkout = params[:share][:can_checkout]

    if @share.save
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
