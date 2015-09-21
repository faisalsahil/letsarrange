class RequestsController < ApplicationController
  ALLOWED_CONTACTS = %i(phone email ouid)
  respond_to :html, :js
  skip_before_filter :authenticate_user!, only: [:show, :new, :new_with_contact, :new_with_organization, :create]
  before_filter :can_make_requests, only: :create
  before_filter :strip_plus_sign, only: [:new_with_contact, :new_with_organization]

  def new
    @request = if current_user
      current_user.default_org_resource.requests.build(contact_point: current_user.sorted_preferred_contacts.first)
    else
      Request.new
    end
    js logged_in: current_user.present? # passing info to paloma JS controller
    respond_with @request
  end

  def new_with_contact
    redirect_to_new_request
  end

  def new_with_organization
    organization = Organization.find_by(uniqueid: Organization.clean(params[:ouid]))
    if organization
      params[:oname] = organization.name
      redirect_to_new_request
    else
      redirect_to root_path
    end
  end

  def create
    params.require(:request).permit!
    @request = RequestsDispatcher.dispatch(params[:request], current_user)
    flash[:error] = 'Please review your request' unless @request.persisted?
    render :create
  end

  def index
    @organizations = current_user.manageable_organizations.includes(:requests)
    respond_with @organizations
  end

  def show
    @request = Request.find params[:id]
    @line_items = @request.line_items.including_associations.order(id: :asc)
  end

  def close
    request = Request.find(params[:request_id])
    fail AccessDeniedError unless request.closable_by?(current_user)
    request.close(current_user)

    if request.errors.empty?
      redirect_to requests_path, notice: 'The request has been successfully closed'
    else
      redirect_to request, alert: request.errors_sentence
    end
  end

  private

  def can_make_requests
    #redirect_to contact_points_path, alert: 'You need to have at least one verified phone number to be able to make requests' unless current_user.can_make_requests?
    @in_modal = true
    if current_user
      unless current_user.can_make_requests?
        unverified_contacts = current_user.contacts_phone.verifiable.presence
        if unverified_contacts
          @voice = unverified_contacts.find(&:voice?)
          @sms = unverified_contacts.find(&:sms?)
          @without_refresh = '1'
          render 'voice_verifications/show_modal', formats: [:js] unless current_user.can_make_requests?
        else
          render 'contact_point_voices/new_phone_modal', formats: [:js]
        end
      end
    else
      render 'devise/sessions/new', formats: [:js]
    end
  end

  def strip_plus_sign
    ALLOWED_CONTACTS.each { |attr| params[attr][0] = '' if params[attr] }
  end

  def redirect_to_new_request
    redirect_to new_request_url(params.slice(:oname, *ALLOWED_CONTACTS))
  end
end