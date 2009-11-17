class SharesController < ApplicationController
  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  before_filter :find_document_share
  before_filter :find_share_by_id, :only => [ :show, :edit, :update, :toggle_update, :toggle_checkout ]

  def index
    redirect_to(document_path(@document))
  end

  def new
    @share = @document.shares.new
  end

  def create
    @share = @document.shares.new
    @share.owner = current_user
    user = User.find_by_login params[:share][:login] unless params[:share].nil?

    if !user.nil?

      @share.user = user
      if @share.save
        make_audit(@document, @share, current_user, "create share")
        flash[:notice] = 'Share was successfully created.'
        redirect_to(document_path(@document))
      else
        flash[:notice] = 'Share could not be created created.'
        redirect_to(document_path(@document))
      end

    else
        flash[:error] = 'That user does not exist.'
        render :action => "new"
    end
  end

  def show
    redirect_to(document_path(@document))
  end

  def edit
    @login = @share.user.login
  end

  def update
    user = User.find_by_login params[:share][:login] unless params[:share].nil?
    if !user.nil?

      @share.user = user
      if @share.save
        make_audit(@document, @share, current_user, "update share")
        flash[:notice] = 'Share was successfully updated.'
        redirect_to(document_path(@document))
      else
        flash[:notice] = 'Share could not be created updated.'
        redirect_to(document_path(@document))
      end

    else
        flash[:error] = 'That user does not exist.'
        render :action => "edit"
    end
  end

  def destroy
    begin
      @share = @document.shares.find(params[:id])
      make_audit(@document, nil, current_user, "delete share, ID:'#{@share.id}', Owner:'#{@share.owner_id}', User:'#{@share.user_id}', Update?:'#{@share.can_update}', Checkout?:'#{@share.can_checkout}'" )

      @document.shares.find(params[:id]).destroy
      flash[:notice] = 'Share was successfully deleted.'
      redirect_to(document_path(@document))
    rescue
      flash[:error] = 'Share delete failed.'
      redirect_to(document_path(@document))
    end
  end

  def toggle_update
    if @share.can_update?
      @share.can_update = false
      @share.can_checkout = false
    else
      @share.can_update = true
    end

    if @share.save
      make_audit(@document, @share, current_user, "share permission change, Update?:'#{@share.can_update}', Checkout?:'#{@share.can_checkout}'")
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
      make_audit(@document, @share, current_user, "share permission change, Update?:'#{@share.can_update}', Checkout?:'#{@share.can_checkout}'")
      flash[:notice] = 'Share was successfully updated.'
      redirect_to(document_path(@document))
    else
      flash[:error] = 'Share update failed.'
      redirect_to(document_path(@document))
    end
  end

end
