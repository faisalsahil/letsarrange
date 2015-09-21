class Organizations::ResourcesController < ApplicationController
  before_filter :get_organization
  before_filter :get_org_resource, only: [:edit, :update, :destroy, :set_default, :link_org]

  def index
    @organization_resources = @organization.organization_resources.includes(:resource)
  end

  def new
    @org_resource = @organization.organization_resources.new
  end

  def create
    if params[:resource_name].blank?
      @org_resource = @organization.organization_resources.new
      flash.now[:danger] = 'No resource selected and/or no new resource name given'
      render :new
    else
      OrganizationResource.find_or_create_within_org(@organization, params[:resource_name])

      flash[:success] = 'New resource successfully added'
      redirect_to organization_resources_path(@organization)
    end
  end

  def edit
    js resource_id: @org_resource.resource_id
  end

  def update
    if @org_resource.update(params.require(:organization_resource).permit!)
      flash[:success] = 'Organization resource successfully updated'
      redirect_to organization_resources_path(@organization)
    else
      render :edit
    end
  end

  def destroy
    dispatcher = OrganizationResourceDispatcher.new(@org_resource)

    if dispatcher.destroy_by(current_user)
      flash[:success] = 'Resource successfully unlinked'
    else
      flash[:danger] = dispatcher.error_message
    end

    redirect_to organization_resources_path(@organization)
  end

  def set_default
    current_user.update(default_org_resource: @org_resource)
    flash[:success] = "User's default org-resource successfully updated"
    redirect_to organization_resources_path(@organization)
  end

  def link_org
    if organization = Organization.find_by(uniqueid: params[:uniqueid])
      organization.add_resource(@org_resource.resource)
      flash[:success] = "Resource linked to new organization successfully"
      redirect_to organization_resources_path(@organization)
    else
      flash[:danger] = "Organization NOT found"
      redirect_to edit_organization_resource_path(@organization, @org_resource)
    end
  end


  private

  def get_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def get_org_resource
    @org_resource = @organization.organization_resources.find(params[:id])
  end

end
