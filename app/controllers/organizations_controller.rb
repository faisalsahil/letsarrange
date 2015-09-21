class OrganizationsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:by_contact_point, :by_id]
  before_filter :get_organization, only: [:edit, :update, :destroy, :visibility]
  before_filter :get_org_user_name, only: [:edit, :update, :new, :create]
  respond_to :json

  def by_contact_point
    contact_point = ContactPoint.from_hash(params.require(:contact_point).permit(:voice, :sms, :email))
    user = User.find_user(contact_point).first
    organizations = user ? user.organizations : []
    render json: organizations, only: [:uniqueid, :name]
  end

  def by_id
    clean_id = Organization.clean(params[:q])
    organizations = Organization.private.typeahead_select.by_uniqueid(clean_id)
    organizations.concat(Organization.public.typeahead_order.typeahead_select.where('uniqueid LIKE ?', "%#{ clean_id }%"))

    render json: organizations, only: [:uniqueid, :name]
  end

  def index
    @organizations = ([current_user.default_org] + current_user.organizations).compact.uniq
  end

  def trusted
    organizations = current_user.manageable_organizations.order(:name)
    # if there's a params[:resource_id] then it means we want to exclude orgs that already manage that 'resource_id'
    if params[:resource_id]
      orgs_table = Arel::Table.new(:organizations)
      ids_to_exclude = OrganizationResource.where(resource_id: params[:resource_id]).pluck(:organization_id)
      organizations = current_user.manageable_organizations.where(orgs_table[:id].not_in ids_to_exclude).compact.uniq
    end
    # if we have the flag params[:only_with_resources] then it means we want orgs that have at least one resource
    if params[:only_with_resources]
      organizations = organizations.reject{|org| org.resources.blank?}
    end

    render json: organizations, only: [:uniqueid, :name]
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.create_with_user(organization_params,
                                                  current_user,
                                                  params[:org_user_name])
    if @organization.persisted?
      flash[:success] = 'The organization was successfully created'
      redirect_to organizations_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    ActiveRecord::Base.transaction do
      org_user = @organization.organization_users.find_by(user_id: current_user)
      if @organization.update(organization_params) && org_user.update(name: params[:org_user_name])
        flash[:success] = 'The organization was successfully updated'
        redirect_to organizations_path
      else
        render :edit
      end
    end
  end

  def destroy
    dispatcher = OrganizationDispatcher.new(@organization)

    if dispatcher.destroy_by(current_user)
      flash[:success] = 'The organization was successfully deleted'
    else
      flash[:danger] = dispatcher.error_message
    end

    redirect_to organizations_path
  end

  def unlink
    organization = current_user.organizations.find(params[:organization_id])
    dispatcher = OrganizationDispatcher.new(organization)

    if dispatcher.unlink_by(current_user)
      flash[:success] = 'You were successfully unlinked from the organization'
    else
      flash[:danger] = dispatcher.error_message
    end

    redirect_to organizations_path
  end

  def visibility
    if @organization.update(visibility: params[:private] == '1' ? 'private' : 'public')
      flash.now[:success] = 'The organization was successfully updated'
      render :refresh
    else
      render_flash_error('An error occurred while trying to update the organization')
    end
  end


  private

  def get_organization
    @organization = current_user.manageable_organizations.find(params[:id]||params[:organization_id])
  end

  def get_org_user_name
    @org_user_name = OrganizationUser.name_for(organization: @organization, user: current_user) || current_user.name
  end

  def organization_params
    params.require(:organization).permit!
  end

end