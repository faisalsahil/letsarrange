class OrganizationResourcesController < ApplicationController
  skip_before_filter :authenticate_user!, only: :index
  skip_before_filter :verify_authenticity_token, only: :find_or_create
	respond_to :json

	def index
    contact_point = ContactPoint.from_hash(params.require(:contact_point)) if params[:contact_point].present?

    organization = if contact_point && params['organization']['uniqueid'] == "anyone_org_option"
		  user = User.find_user(contact_point).first
      user ? user.default_org : nil
    else
      Organization.by_uniqueid(params['organization']['uniqueid']).first || Organization.by_name(params['organization']['uniqueid']).first
    end

    if organization
		  resources = OrganizationResource.where(organization: organization, visibility: "public" )
		  render json: resources, only: [:name]
    else
      render json: []
    end
	end

  def find_or_create
    # if there's no Org Data then we use the author's default org resource
    org_resource = if params[:uniqueid].blank?
      current_user.default_org_resource
    else
      # we create the organization if it's a new one. Otherwise we use the existing one passed through params
      organization = if params[:created].present? # it's a new Organization
        Organization.create_by_name_and_user!(params[:name], current_user, 'private', params[:orguser])
      else # it's an existing Organization (no matter if it's with existing or new resource)
        current_user.organizations.find_by!(uniqueid: params[:uniqueid])
      end

      resource_name = OrganizationResource.resource_default_name(params[:resource])
      OrganizationResource.find_or_create_within_org(organization, resource_name)
    end

    render json: org_resource, only: [:id, :name], methods: :org_uniqueid
  end
end