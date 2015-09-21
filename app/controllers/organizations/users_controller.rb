class Organizations::UsersController < ApplicationController
  before_filter :get_organization
  before_filter :get_org_user, only: [:edit, :update, :destroy, :set_default, :trust]

  def index
    @organization_users = @organization.organization_users.includes(:user)
  end

  def new
    @org_user = @organization.organization_users.new
    js org_id: @organization.id
  end

  def create
    @org_user = @organization.organization_users.new
    if user = User.find_by(uniqueid: params[:uniqueid])
      @organization.add_user(user)

      flash[:success] = 'New user successfully linked'
      redirect_to organization_users_path(@organization)
    else
      flash.now[:danger] = 'No user selected'
      render :new
    end
  end

  def edit
  end

  def update
    if @org_user.update(params.require(:organization_user).permit!)
      flash[:success] = 'Organization user successfully updated'
      redirect_to organization_users_path(@organization)
    else
      render :edit
    end
  end

  def destroy
    dispatcher = OrganizationUserDispatcher.new(@org_user)

    if dispatcher.destroy_by(current_user)
      flash[:success] = 'User successfully unlinked'
    else
      flash[:danger] = 'User can not be unlinked'
    end

    redirect_to organization_users_path(@organization)
  end

  def set_default
    @organization.update(default_user: @org_user.user)
    flash[:success] = 'Default user successfully updated'
    redirect_to organization_users_path(@organization)
  end

  def trust
    @org_user.set_as_trusted
    redirect_to organization_users_path(@organization)
  end

  private

  def get_organization
    @organization = current_user.manageable_organizations.find(params[:organization_id])
  end

  def get_org_user
    @org_user = @organization.organization_users.find(params[:id])
  end

end
