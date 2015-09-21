require 'test_helper'

class VoiceVerificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    enable_js
  end

  test 'a user should be able to verify a voice contact point' do
    fake_sign_in_user
    visit contact_points_path
    page.execute_script("$('[placeholder=\"Phone\"]').val('(345) 111-1111')")
    click_button 'Add as voice'
    assert find('#voices').has_content?('(345) 111-1111 (unverified)')
    click_link 'verify'

    created_cp = ContactPoint::Voice.last
    VoiceSender.expects(:unverify_outgoing_caller).with(created_cp.number)
    TwilioApi.stubs(:client).returns(stub(account: stub(outgoing_caller_ids: stub(create: Struct.new(:validation_code, :call_sid).new('123456', 'callsid')))))

    click_link 'Call me now'
    assert find('#voice_verification_code').has_content?('123456')

    post contact_point_voice_verification_path(created_cp),
         'CallSid' => 'callsid',
         'VerificationStatus' => 'success',
         'OutgoingCallerIdSid' => 'outgoingsid'

    click_link 'Close'
    assert find('#voices').has_content?('(345) 111-1111 (active)')
  end
end