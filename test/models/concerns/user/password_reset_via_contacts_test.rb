require 'test_helper'

class User::PasswordResetViaContactsTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Voice.create!(user: @user, description: '(345) 123-4567', status: ContactPointState::VERIFIED)
  end

  def send_reset_password_instructions(args = {})
    @user.send_reset_password_instructions( { description: '(345) 123-4567', type: 'voice' }.merge(args))
  end

  test 'it should add an association to user for voice_reset_contact' do
    assert @user.respond_to?(:voice_reset_contact)
  end

  test 'send_reset_password_instructions should normalize the phone number' do
    ContactPoint::Phone.expects(:normalize).with('(345) 123-4567').returns('13451234567')
    send_reset_password_instructions
  end

  test 'send_reset_password_instructions should set a temp contact point for password reset' do
    @user.expects(:password_reset_contact=).with(@contact_point)
    @user.expects(:password_reset_contact=).with(nil)
    @user.stubs(:send_devise_notification)
    send_reset_password_instructions
  end

  test 'send_reset_password_instructions should clear voice_reset fields if the contact point chosen is not a voice' do
    ContactPoint::Sms.create!(user: @user, description: '(345) 123-4567', status: ContactPointState::VERIFIED)
    @user.expects(:clear_voice_reset)
    send_reset_password_instructions(type: 'sms')
  end

  test 'send_reset_password_instructions should return the raw reset token generated' do
    raw_token = send_reset_password_instructions
    assert_equal @user.reset_password_token, Devise.token_generator.digest(User, :reset_password_token, raw_token)
  end

  test 'send_reset_password_instructions should raise ActiveRecord::RecordNotFound if there is no verified contact point that matches' do
    ContactPoint::Sms.create!(user: @user, description: '13451234568')
    assert_raise(ActiveRecord::RecordNotFound) { @user.send_reset_password_instructions(description: '(345) 123-4568', type: 'sms') }
  end

  test 'send_devise_notification should call send_password_reset on the contact point if the notification is reset_password_instructions' do
    contact_point = ContactPoint::Sms.create!(user: @user, description: '13451234567')
    contact_point.expects(:send_password_reset).with('token')
    @user.password_reset_contact = contact_point
    @user.send(:send_devise_notification, :reset_password_instructions, 'token')
  end

  test 'send_devise_notification should call super if the notification is not reset_password_instructions' do
    contact_point = ContactPoint::Sms.create!(user: @user, description: '13451234567')
    contact_point.expects(:send_password_reset).never
    @user.password_reset_contact = contact_point
    Devise::Mailer.any_instance.expects(:unlock_instructions)
    @user.send(:send_devise_notification, :unlock_instructions, 'token')
  end

  test 'setup_for_reset_via_voice should update the user with a voice_reset_contact and a voice_reset_code' do
    @user.stubs(:generate_voice_code).returns('123456')
    @user.update!(voice_reset_contact_id: nil, voice_reset_code: nil)
    @user.setup_for_reset_via_voice(@contact_point)
    assert_equal @contact_point, @user.voice_reset_contact
    assert_equal '123456', @user.voice_reset_code
  end

  test 'reset_password_via_voice should clear voice_reset fields if the code given matchs the code stored' do
    @user.update!(voice_reset_contact_id: 1, voice_reset_code: 'current code')
    @user.expects(:clear_voice_reset)
    @user.reset_password_via_voice('current code')
  end

  test 'clear_voice_reset should clear the voice_reset_fields' do
    @user.update!(voice_reset_contact_id: 1, voice_reset_code: '123456')
    @user.send(:clear_voice_reset)
    assert_nil @user.voice_reset_contact
    assert_nil @user.voice_reset_code
  end

  test 'reset_password_via_voice should do nothing if the code given does not match the code stored' do
    @user.update!(voice_reset_contact_id: 1, voice_reset_code: 'stored code')
    @user.reset_password_via_voice('current code')
    assert_equal 1, @user.voice_reset_contact_id
    assert_equal 'stored code', @user.voice_reset_code
  end

  test 'voice_reset_in_progress? should return true if the user has a code stored' do
    @user.update!(voice_reset_code: 'stored code')
    assert @user.voice_reset_in_progress?
  end

  test 'voice_reset_in_progress? should return false if the user does not have a code stored' do
    @user.update!(voice_reset_code: nil)
    assert !@user.voice_reset_in_progress?
  end

  test 'voice_reset_active? should return true if the reset_password_token has not expired' do
    @user.update!(reset_password_sent_at: 10.minutes.ago)
    assert @user.voice_reset_active?
  end

  test 'voice_reset_active? should return false if the reset_password_token has expired' do
    @user.update!(reset_password_sent_at: 20.minutes.ago)
    assert !@user.voice_reset_active?
  end

  test 'generate_voice_code should return a number between 100000 and 999999' do
    SecureRandom.expects(:random_number).with(900_000).returns(123456)
    assert_equal '223456', @user.send(:generate_voice_code)
  end

  test 'self.send_reset_password_instructions should call send_reset_password_instructions on the user fetched' do
    User.expects(:find_by!).with(uniqueid: @user.uniqueid).returns(@user)
    @user.expects(:send_reset_password_instructions).with(:contact_point_info)
    User.send_reset_password_instructions(uniqueid: @user.uniqueid, contact_point_for_reset: :contact_point_info)
  end

  test 'self.send_reset_password_instructions should suppress ActiveRecord::RecordNotFound errors' do
    assert_nothing_raised { User.send_reset_password_instructions(uniqueid: @user.uniqueid.succ, contact_point_for_reset: :contact_point_info) }
  end

  test 'self.send_reset_password_instructions should return a fake token if there is no matching records' do
    User.expects(:fake_token).returns('a token')
    assert_equal 'a token', User.send_reset_password_instructions(uniqueid: @user.uniqueid.succ, contact_point_for_reset: :contact_point_info)
  end

  test 'find_by_encrypted_token should encrypt the token given and find the user' do
    token = send_reset_password_instructions
    assert @user, User.find_by_encrypted_token(token)
  end

  test 'fake_token should return a token shorter than a real token' do
    real_token = Devise.friendly_token
    assert real_token.length > User.fake_token.length
  end

  test 'fake_token should drop the last char of a real token' do
    Devise.expects(:friendly_token).returns('a token')
    assert_equal 'a toke', User.fake_token
  end

  test 'fake_token? should return true if the token given is fake' do
    assert User.fake_token?(User.fake_token)
  end

  test 'fake_token? should return false if the token given is real' do
    assert !User.fake_token?(Devise.friendly_token)
  end

  test 'fake_code should return always the same code for a given token' do
    assert_equal User.fake_code('some token'), User.fake_code('some token')
  end
end