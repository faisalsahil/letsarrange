class ContactPointsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:index, :for_privacy_options]
  before_filter :sign_in_by_url_mapping, only: :index

  def create
    @contact_point = current_user.contact_points.create_with_type(contact_point_params)
    if @contact_point.persisted?
      flash.now[:success] = @contact_point.email? ? 'You will receive an email with instructions about how to verify your email address in a few minutes' : 'The contact method was successfully added'
      render(@contact_point.phone? ? 'create_phone' : 'create_email')
    else
      render_flash_error(@contact_point.errors_sentence)
    end
  end

  def create_both
    result = ContactPoint.create_sms_and_phone(current_user, contact_point_params[:description])
    if result[:created].present?
      @contact_points = result[:created]
      flash.now[:success] = 'The contact methods were successfully added'
    else
      render_flash_error(result[:failed][0].errors_sentence)
    end
  end

  def destroy
    @contact_point = current_user.contact_points.find(params[:id])
    @contact_point.soft_destroy
    flash.now[:success] = 'The contact method was successfully removed'
  end

  def index
    @voices = current_user.sorted_voices
    @smss = current_user.sorted_smss
    @emails = current_user.sorted_emails
  end

  def refresh
    @contact_point = fetch_contact_point
  end

  def enable
    change_status(:enable)
  end

  def disable
    change_status(:disable)
  end

  def enable_notifications
    change_status(params[:disabled].present? ? :disable_notifications : :enable_notifications)
  end

  def for_privacy_options
    collection = if current_user
      current_user.sorted_preferred_contacts.map do |cp|
        { id: cp.id, description: cp.to_s }
      end.uniq{|x| x[:description] }
    else
      [
        { id: '-1', description: "Show my phone" },
        { id: '-2', description: "Show my email" }
      ]
    end
    collection << { id: '', description: "Don't share contact details" }

    render json: collection
  end

  private

  def contact_point_params
    params.require(:contact_point).permit(:contact_type, :description)
  end

  def render_flash_error(message)
    flash.now[:error] = message
    render_flash_only
  end

  def fetch_contact_point
    current_user.contact_points.find(params[:contact_point_id])
  end

  def change_status(transition)
    @contact_point = fetch_contact_point
    if @contact_point.send(transition)
      flash.now[:success] = 'The contact method was successfully updated'
      render :refresh_all
    else
      render_flash_error('An error occurred while trying to update the contact method')
    end
  end
end