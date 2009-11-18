class SharesController < ApplicationController
  prepend_before_filter :login_required, :session_expire, :update_activity_time
  require_role ["employee", "manager", "corporate"] # role1 or role2 or role3

  before_filter :find_document_share
  before_filter :find_share_by_id, :only => [ :show, :edit, :update, :toggle_update, :toggle_checkout ]

  def index
    redirect_to(document_path(@document)) ; return
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
        make_audit(@document, @share, current_user, "create share, ID:'#{@share.id}', Owner:'#{@share.owner_id}, #{@share.owner.login}', User:'#{@share.user_id}, #{@share.user.login}'")
        flash[:notice] = 'Share successfully created.'
        redirect_to(document_path(@document)) ; return
      else
        flash[:notice] = 'Share could not be created.'
        redirect_to(document_path(@document)) ; return
      end

    else
        flash[:error] = 'That user does not exist.'
        render :action => "new"
    end
  end

  def show
    redirect_to(document_path(@document)) ; return
  end

  def edit
    @login = @share.user.login
  end

  def update
    user = User.find_by_login params[:share][:login] unless params[:share].nil?
    if !user.nil?

      @share.user = user
      if @share.save
        make_audit(@document, @share, current_user, "update share, ID:'#{@share.id}', Owner:'#{@share.owner_id}, #{@share.owner.login}', User:'#{@share.user_id}, #{@share.user.login}'")
        flash[:notice] = 'Share successfully updated.'
        redirect_to(document_path(@document)) ; return
      else
        flash[:notice] = 'Share could not be updated.'
        redirect_to(document_path(@document)) ; return
      end

    else
        flash[:error] = 'That user does not exist.'
        render :action => "edit"
    end
  end

  def destroy
    begin
      @share = @document.shares.find(params[:id])
      make_audit(@document, nil, current_user, "delete share, ID:'#{@share.id}', Owner:'#{@share.owner_id}, #{@share.owner.login}', User:'#{@share.user_id}, #{@share.user.login}', Update?:'#{@share.can_update}', Checkout?:'#{@share.can_checkout}'" )

      @document.shares.find(params[:id]).destroy
      flash[:notice] = 'Share successfully deleted.'
      redirect_to(document_path(@document)) ; return
    rescue
      flash[:error] = 'Share delete failed.'
      redirect_to(document_path(@document)) ; return
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
      make_audit(@document, @share, current_user, "share permission change, ID:'#{@share.id}', Owner:'#{@share.owner_id}, #{@share.owner.login}', User:'#{@share.user_id}, #{@share.user.login}', Update?:'#{@share.can_update}', Checkout?:'#{@share.can_checkout}'")
      flash[:notice] = 'Share successfully updated.'
      redirect_to(document_path(@document)) ; return
    else
      flash[:error] = 'Share update failed.'
      redirect_to(document_path(@document)) ; return
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
      make_audit(@document, @share, current_user, "share permission change, ID:'#{@share.id}', Owner:'#{@share.owner_id}, #{@share.owner.login}', User:'#{@share.user_id}, #{@share.user.login}', Update?:'#{@share.can_update}', Checkout?:'#{@share.can_checkout}'")
      flash[:notice] = 'Share successfully updated.'
      redirect_to(document_path(@document)) ; return
    else
      flash[:error] = 'Share update failed.'
      redirect_to(document_path(@document)) ; return
    end
  end

end
