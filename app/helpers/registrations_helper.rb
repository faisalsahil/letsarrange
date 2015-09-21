module RegistrationsHelper
  def phone_errors_on_sign_up(user)
    contact_errors_on_sign_up(user, :phone)
  end

  def email_errors_on_sign_up(user)
    contact_errors_on_sign_up(user, :email)
  end

  private

  def contact_errors_on_sign_up(user, short_type)
    failed_cp = user.contact_points.find { |cp| cp.send("#{ short_type }?") && !cp.persisted? }
    failed_cp.errors_sentence if failed_cp
  end
end