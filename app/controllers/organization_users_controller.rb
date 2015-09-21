class OrganizationUsersController < ApplicationController
  skip_before_filter :authenticate_user!, only: :index
	respond_to :json

  def index
    contact_point = ContactPoint.from_hash(params.require(:contact_point)) if params[:contact_point].present?
    organization  = if contact_point && params['organization']['uniqueid'] == "anyone_org_option"
      user = User.find_user(contact_point).first
      user ? user.default_org : nil
    else
      Organization.by_uniqueid(params['organization']['uniqueid']).first
    end

    if organization && current_user
      org_user  = OrganizationUser.where(organization: organization, user: current_user).first
      render json: org_user, only: [:name]
    else
      render json: []
    end
  end

end