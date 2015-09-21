require 'test_helper'

class ContactPointControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    enable_js
    @user = fake_sign_in_user
  end

  test 'a user should be able to enable notifications for a verified contact point' do
    created_cp = ContactPoint::Sms.create!(user: @user, description: '13459999999', status: ContactPointState::VERIFIED, notifications_enabled: false)
    visit contact_points_path
    assert find("#contact_point_sms_#{ created_cp.id }").has_content?('verified')
    within("#contact_point_sms_#{ created_cp.id }") { click_link 'enable notifications' }
    assert find("#contact_point_sms_#{ created_cp.id }").has_content?('notifications enabled')
  end

  test 'a user should be able to disable notifications for a contact point with notifications enabled' do
    created_cp = ContactPoint::Sms.create!(user: @user, description: '13459999999', status: ContactPointState::VERIFIED)
    visit contact_points_path
    assert find("#contact_point_sms_#{ created_cp.id }").has_content?('notifications enabled')
    within("#contact_point_sms_#{ created_cp.id }") { click_link 'disable notifications' }
    assert find("#contact_point_sms_#{ created_cp.id }").has_content?('verified')
  end

  test 'a user should be able to enable notifications for a voice contact point and therefore disable notifications for the previous one' do
    previous_cp = ContactPoint::Voice.create!(user: @user, description: '13459999999', status: ContactPointState::VERIFIED)
    created_cp = ContactPoint::Voice.create!(user: @user, description: '13458888888', status: ContactPointState::VERIFIED)
    visit contact_points_path
    assert find("#contact_point_voice_#{ previous_cp.id }").has_content?('(active)')
    assert find("#contact_point_voice_#{ created_cp.id }").has_content?('(verified)')
    within("#contact_point_voice_#{ created_cp.id }") { click_link 'set as active' }
    assert find("#contact_point_voice_#{ previous_cp.id }").has_content?('(verified)')
    assert find("#contact_point_voice_#{ created_cp.id }").has_content?('(active)')
  end

  test 'a user should be able to disable notifications for the current preferred voice and therefore enable notifications for the other one' do
    previous_cp = ContactPoint::Voice.create!(user: @user, description: '13459999999', status: ContactPointState::VERIFIED)
    created_cp = ContactPoint::Voice.create!(user: @user, description: '13458888888', status: ContactPointState::VERIFIED)
    visit contact_points_path
    assert find("#contact_point_voice_#{ previous_cp.id }").has_content?('(active)')
    assert find("#contact_point_voice_#{ created_cp.id }").has_content?('(verified)')
    within("#contact_point_voice_#{ previous_cp.id }") { click_link 'remove as active' }
    assert find("#contact_point_voice_#{ previous_cp.id }").has_content?('(verified)')
    assert find("#contact_point_voice_#{ created_cp.id }").has_content?('(active)')
  end
end