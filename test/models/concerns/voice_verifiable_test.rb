require 'test_helper'

class VoiceVerifiableTest < ActiveSupport::TestCase
  def setup
    super
    @contact_point = ContactPoint::Voice.new(user: create_user, description: '(345) 123-4567')
  end

  test 'it should have call_sid as alias of confirmation_token' do
    assert_equal 'confirmation_token', ContactPoint::Voice.attribute_aliases['call_sid']
  end

  test 'revoke_outgoing_caller should be called after destroy' do
    @contact_point.expects(:revoke_outgoing_caller)
    @contact_point.save(validate: false)
    @contact_point.destroy
  end

  test 'revoke_outgoing_caller should call revoke_outgoing_caller on VoiceSender' do
    @contact_point.outgoing_caller_sid = 'a_sid'
    @contact_point.save(validate: false)
    @contact_point.stubs(:verified?).returns(true)
    VoiceSender.expects(:revoke_outgoing_caller).with('a_sid')
    @contact_point.destroy
  end

  test 'verify! should change the status to verified if successful' do
    @contact_point.verify!(status: 'success')
    assert_equal ContactPointState::VERIFIED, @contact_point.status
  end

  test 'verify! should not change the status to verified if failed' do
    @contact_point.verify!(status: 'failed')
    assert_equal ContactPointState::UNVERIFIED, @contact_point.status
  end

  test 'verify! should add an error if the code is invalid' do
    @contact_point.verify!(status: 'failed')
    assert_equal ContactPointState::UNVERIFIED, @contact_point.status
    assert_includes @contact_point.errors[:base], 'The code you entered was invalid'
  end

  test 'verify! should call mark_as_verified! if successful' do
    @contact_point.expects(:mark_as_verified!)
    @contact_point.verify!(status: 'success')
  end

  test 'verify! should not call mark_as_verified! if failed' do
    @contact_point.expects(:mark_as_verified!).never
    @contact_point.verify!(status: 'failed')
  end

  test 'verify! should set the outgoing_caller_sid if successful' do
    @contact_point.verify!(status: 'success', outgoing_sid: 'a_sid')
    assert_equal 'a_sid', @contact_point.outgoing_caller_sid
  end

  test 'verify! should not set the outgoing_caller_sid if successful' do
    old_sid = @contact_point.outgoing_caller_sid
    @contact_point.verify!(status: 'failed', outgoing_sid: 'a_sid')
    assert_equal old_sid, @contact_point.outgoing_caller_sid
  end

  test 'send_verification should call send_verification on VoiceSender' do
    VoiceSender.expects(:send_verification).with(@contact_point)
    @contact_point.send_verification
  end
end