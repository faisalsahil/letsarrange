require 'test_helper'

class SmsVerifiableTest < ActiveSupport::TestCase
  def setup
    super
    @code = '123456'
    @contact_point = ContactPoint::Sms.new(user: User.new, description: '(345) 123-4567', confirmation_token: @code, confirmation_sent_at: Time.now.utc)
  end

  test 'verify! should change the status to verified if successful' do
    @contact_point.verify!(@code)
    assert_equal ContactPointState::VERIFIED, @contact_point.status
  end

  test 'verify! should not change the status to verified if failed' do
    @contact_point.verify!(@code.succ)
    assert_equal ContactPointState::UNVERIFIED, @contact_point.status
  end

  test 'verify! should add an error if the code has expired' do
    @contact_point.confirmation_sent_at = 3.days.ago
    @contact_point.verify!(@code)
    assert_equal ContactPointState::UNVERIFIED, @contact_point.status
    assert_includes @contact_point.errors[:base], 'The code has expired, please request a new one'
  end

  test 'verify! should add an error if the code is invalid' do
    @contact_point.verify!(@code.succ)
    assert_equal ContactPointState::UNVERIFIED, @contact_point.status
    assert_includes @contact_point.errors[:base], 'The verification code is invalid'
  end

  test 'verify! should call mark_as_verified! if successful' do
    @contact_point.expects(:mark_as_verified!)
    @contact_point.verify!(@code)
  end

  test 'verify! should not call mark_as_verified! if failed' do
    @contact_point.expects(:mark_as_verified!).never
    @contact_point.verify!(@code.succ)
  end

  test 'has_sms_verification_code? should be true if the confirmation_token is a valid sms verification code' do
    assert @contact_point.send(:has_sms_verification_code?)
  end

  test 'has_sms_verification_code? should be false if the confirmation_token is not a valid sms verification code' do
    @contact_point.confirmation_token = token_of_length(7)
    assert !@contact_point.send(:has_sms_verification_code?)
  end

  test 'generate_sms_verification_code should set confirmation_token to a valid token' do
    @contact_point.save
    @contact_point.send(:generate_sms_verification_code)
    assert_match /^\d{6}$/, @contact_point.confirmation_token
  end

  test 'generate_sms_verification_code should not change the code if the existing one is valid' do
    @contact_point.save
    @contact_point.confirmation_token = @code
    @contact_point.send(:generate_sms_verification_code)
    assert_equal @code, @contact_point.confirmation_token
  end

  test 'send_verification should call generate_sms_verification_code' do
    @contact_point.expects(:generate_sms_verification_code)
    @contact_point.send_verification
  end

  test 'send_verification should call send_verification on SmsSender' do
    @contact_point.stubs(:generate_sms_verification_code)
    SmsSender.expects(:send_verification).with(@contact_point)
    @contact_point.send_verification
  end

  test 'send_verification should create a sms message' do
    SmsSender.stubs(:delay).returns(SmsSender)
    @contact_point.stubs(:generate_sms_verification_code)

    SmsSender.expects(:send_welcome_message).never
    SmsSender.expects(:send_code_message).never
    SmsSender.expects(:delay).returns(SmsSender)
    SmsSender.expects(:deliver_sms).with { |to, _, _| to == @contact_point.number }
    @contact_point.send_verification
  end

  test 'a verification should be sent after creation if the status is unverified' do
    @contact_point.expects(:send_verification)
    @contact_point.status = ContactPointState::UNVERIFIED
    @contact_point.save(validate: false)
  end

  test 'a verification should not be sent after creation if the status is not unverified' do
    @contact_point.expects(:send_verification).never
    @contact_point.status = ContactPointState::TRUSTED
    @contact_point.save(validate: false)
  end
end