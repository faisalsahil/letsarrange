class PasswordMailer < ApplicationMailer
  def password_reset(to_id, token)
    to = ContactPoint::Email.find(to_id)
    @resource = to.user
    @token = token
    mail(to: to.email, subject: 'Reset password instructions', template_path: 'devise/mailer', template_name: 'reset_password_instructions')
  end
end
