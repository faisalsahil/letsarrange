require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  def setup
    super
    Capybara.current_driver = Capybara.javascript_driver 
  end

  test "as a page visitor I should be able to create a new account" do  
    visit '/'
    click_on 'Sign in'
    click_on 'Go to sign up'

    fill_in 'Name (e.g. Jamie Black)', with: 'user1_name'
    fill_in 'User ID (e.g. jamieblack72)',    with: 'user1-ID'
    fill_in 'Password (at least 6 characters)', with: 'password'

    click_on 'Sign up'

    sleep(1)
    assert_equal new_request_path, current_path
  end

  test "as a page visitor I should be able to create a new account and verify my voice number" do
    VoiceSender.stubs(:send_verification).returns('123456')

    visit '/'
    click_on 'Sign in'
    click_on 'Go to sign up'
    fill_in 'Name (e.g. Jamie Black)', with: 'user1_name'
    fill_in 'User ID (e.g. jamieblack72)',    with: 'user1-ID'
    fill_in 'Password (at least 6 characters)', with: 'password'
    #fill_in 'Phone', with: '(345) 111-1111'
    page.execute_script("$('#user_contact_information_phone').val('(345) 111-1111')")
    click_on 'Sign up'

    assert page.has_no_selector?('#voice_verification_code', visible: true)
    click_on 'Call me now'

    assert find('#voice_verification_code').has_content?('123456')
    click_on 'Continue'

    assert_equal contact_points_path, current_path
  end

  test "as a page visitor I should be able to create a new account and verify my sms number" do
    SmsSender.stubs(:send_verification)

    visit '/'
    click_on 'Sign in'
    click_on 'Go to sign up'
    fill_in 'Name (e.g. Jamie Black)', with: 'user1_name'
    fill_in 'User ID (e.g. jamieblack72)',    with: 'user1-ID'
    fill_in 'Password (at least 6 characters)', with: 'password'
    #fill_in 'Phone', with: '(345) 111-1111'
    page.execute_script("$('#user_contact_information_phone').val('(345) 111-1111')")
    check 'Mobile'
    click_on 'Sign up'

    sleep(1)
    fill_in 'Code', with: ContactPoint::Sms.last.confirmation_token
    click_on 'Enter'

    sleep(1)
    assert_equal new_request_path, current_path
    assert User.last.contacts_sms.first.verified?
    assert User.last.contacts_voice.first.trusted?
  end
end
