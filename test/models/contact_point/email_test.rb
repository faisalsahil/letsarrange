require 'test_helper'

class ContactPoint::EmailTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Email.new(user: @user)
  end

  test 'it should verify emails' do
    @contact_point.description = "alfredo@gmail.com"
    assert @contact_point.valid?
  end

  test 'it shouldnt allow invalid emails' do
    @contact_point.description = "alfredo@gmail"
    assert !@contact_point.valid?
    assert @contact_point.errors.messages[:base].include? "Please provide a valid email"
  end

  test 'it should have email as alias of description' do
    assert_equal 'description', ContactPoint::Email.attribute_aliases['email']
  end

  test 'it should validate uniqueness of email' do
    ContactPoint::Email.create(description: 'email@email.com', user: User.new)
    @contact_point.description = "email@email.com"
    assert @contact_point.invalid?
  end

  test 'it sould prepend EmailVerifiable' do
    assert_equal EmailVerifiable, ContactPoint::Email.ancestors.first
  end

  test 'emails_sent_and_received should return the email_messages with from or to equal to its description' do
    @contact_point.description = 'description@email.com'
    e1 = EmailMessage.create!(to: 'description@email.com', from: 'something_else@email.com', body: 'body', subject: 'subject', broadcast_id: 1234)
    e2 = EmailMessage.create!(to: 'something_else@email.com', from: 'description@email.com', body: 'body', subject: 'subject', broadcast_id: 1234)
    EmailMessage.create!(to: 'something_else@email.com', from: 'something_else2@email.com', body: 'body', subject: 'subject', broadcast_id: 1234)
    assert_equal [e1, e2], @contact_point.emails_sent_and_received.to_a
  end

  test 'send_password_reset should relay on EmailSender' do
    cp = ContactPoint::Email.new
    EmailSender.expects(:send_password_reset).with(cp, '123456')
    cp.send_password_reset('123456')
  end
end