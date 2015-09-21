require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    @user = create_user(name: 'name of u1', uniqueid: 'u1')
    @unverified = ContactPoint::Sms.create!(user: @user, description: '(345) 999-9999')
    @unverified_code = UrlMapping.create_for(@unverified).code
    @trusted = ContactPoint::Sms.create!(user: @user, description: '(345) 999-9998', status: ContactPointState::TRUSTED)
    @trusted_code = UrlMapping.create_for(@trusted).code
    verified = ContactPoint::Sms.create!(user: @user, description: '(345) 999-9997', status: ContactPointState::TRUSTED)
    verified.mark_as_verified!
    @verified_code = UrlMapping.create_for(verified).code
  end

  def assert_current_user_name(name)
    # click_link 'Settings'
    visit '/users/edit'
    assert_equal name, find('#user_name').value
  end

  test 'an unidentified visitor with a trusted code should be able to login' do
    visit contact_points_path(code: @trusted_code)

    assert_equal contact_points_path, current_path
    assert_current_user_name 'name of u1'
    assert @trusted.reload.verified?
  end

  test 'an unidentified visitor with an unverified code should not be able to login' do
    visit contact_points_path(code: @unverified_code)

    assert_equal new_user_session_path, current_path
    assert @unverified.reload.unverified?
  end

  test 'an unidentified visitor with a verified code should be able to login' do
    visit contact_points_path(code: @verified_code)

    assert_equal contact_points_path, current_path
    assert_current_user_name 'name of u1'
  end

  test 'a user with a trusted code should be able to login as the contact point owner' do
    Capybara.current_driver = Capybara.javascript_driver 
    fake_sign_in_user
    visit contact_points_path(code: @trusted_code)

    assert_equal contact_points_path, current_path
    assert_current_user_name 'name of u1'
    assert @trusted.reload.verified?
  end

  test 'a user with an unverified code should be able to login and verify if he is the owner of the contact point' do
    Capybara.current_driver = Capybara.javascript_driver 
    owner = fake_sign_in_user(name: 'owner of the cp')
    @unverified.update(user: owner)
    visit contact_points_path(code: @unverified_code)

    assert_equal contact_points_path, current_path
    assert_current_user_name 'owner of the cp'
    assert page.has_content?('Your number was successfully verified')
    assert @unverified.reload.verified?
  end

  test 'a user with an unverified code should be able to login but not verify if he is not the owner of the contact point' do
    Capybara.current_driver = Capybara.javascript_driver 
    fake_sign_in_user(name: 'not owner of the cp')
    visit contact_points_path(code: @unverified_code)

    assert_equal contact_points_path, current_path
    assert_current_user_name 'not owner of the cp'
    assert @unverified.reload.unverified?
  end

  test 'a user with a verified code should be able to login as the owner of the contact point' do
    Capybara.current_driver = Capybara.javascript_driver 
    fake_sign_in_user(name: 'not owner of the cp')
    visit contact_points_path(code: @verified_code)

    assert_equal contact_points_path, current_path
    assert_current_user_name 'name of u1'
  end
end