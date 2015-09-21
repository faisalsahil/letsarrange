class ContactPointVoicesController < ApplicationController
  def create
    phone = voice_params[:phone]
    sms_capable = voice_params[:sms_capable] == '1'
    cp_attrs = [ { type: ContactPoint.full_type(:voice), description: phone }]
    cp_attrs << { type: ContactPoint.full_type(:sms), description: phone } if sms_capable
    if current_user.update(contact_points_attributes: cp_attrs)
      @voice = current_user.contacts_voice.first
      @sms = current_user.contacts_sms.first
    else
      render :new_phone_modal
    end
  end

  private

  def voice_params
    params.require(:contact_point_voice).permit(:phone, :sms_capable)
  end
end