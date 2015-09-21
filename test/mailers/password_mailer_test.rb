require 'test_helper'

class PasswordMailerTest < ActionMailer::TestCase
  test 'password_reset should send a mail to the contact point given with the token' do
    contact_point = ContactPoint::Email.new(description: 'email@email.com')
    contact_point.save(validate: false)
    assert_no_difference 'EmailMessage.count' do
      PasswordMailer.any_instance.expects(:mail).with(to: contact_point.email, subject: 'Reset password instructions', template_path: 'devise/mailer', template_name: 'reset_password_instructions')
      PasswordMailer.send(:new).password_reset(contact_point.id, 'token')
    end
  end

  test 'error_message should send a mail with the message given as body' do
    BroadcastMailer.any_instance.expects(:mail).with(to: 'to@to.com', from: 'from@from.com', body: 'exception message', subject: 'An error occurred')
    BroadcastMailer.send(:new).error_message('from@from.com', 'to@to.com', 'exception message')
  end
end
