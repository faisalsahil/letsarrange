require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    Capybara.current_driver = Capybara.javascript_driver
    @user = create_user
  end

  test 'an unidentified user should be able to request a password reset' do
    visit_login
    click_on 'Forgot password?'
    assert_equal new_user_password_path, current_path
  end

  test 'an unidentified user should be able to request a wrong password reset via email' do
    visit new_user_password_path

    fill_in 'User ID', with: 'random user'
    click_link 'Email'
    fill_in 'Email address', with: 'someemail@email.com'
    click_link 'Send instructions'

    assert page.has_content?('If these match a userid, you will receive instructions on how to reset your password')
    assert_equal new_user_session_path, current_path
    assert_nil @user.reset_password_token
  end
  test 'an unidentified user should be able to request a wrong password reset via sms' do
    visit new_user_password_path

    fill_in 'User ID', with: 'random user'
    click_link 'Phone'
    #fill_in 'Phone number', with: '3451234567'
    page.execute_script("$('#phone_for_reset').val('(345) 123-4567')")
    click_link 'Text'

    assert page.has_content?('If these match a userid, you will receive instructions on how to reset your password')
    assert_equal new_user_session_path, current_path
    assert_nil @user.reset_password_token
  end

  test 'an unidentified user should be able to request a wrong password reset via voice' do
    User.stubs(:fake_token).returns('token')
    fake_code = User.fake_code('token')
    visit new_user_password_path

    fill_in 'User ID', with: 'random user'
    click_link 'Phone'
    #fill_in 'Phone number', with: '3451234567'
    page.execute_script("$('#phone_for_reset').val('(345) 123-4567')")
    click_link 'Voice'

    assert page.has_content?('To finish the process, you must call')
    assert find('.voice-reset-code').has_content?(fake_code)
    assert_equal voice_password_path('token'), current_path
    assert_nil @user.reset_password_token

    click_link 'Reset password'

    assert page.has_content?('To finish the process, you must call')
    assert find('.voice-reset-code').has_content?(fake_code)
    assert page.has_content?('You must first complete the validation process by calling to the corresponding phone number')
    assert_equal voice_password_path('token'), current_path
  end

  test 'an unidentified user should be able to request a password reset via email' do
    contact_point = ContactPoint::Email.create!(user: @user, description: 'email@email.com', status: ContactPointState::VERIFIED)
    Devise.stubs(:friendly_token).returns('token')

    PasswordMailer.expects(:delay).returns(PasswordMailer)
    PasswordMailer.expects(:password_reset).with(contact_point.id, 'token')

    visit new_user_password_path
    fill_in 'User ID', with: @user.uniqueid
    click_link 'Email'
    fill_in 'Email address', with: 'email@email.com'
    click_link 'Send instructions'

    synchronize do
      assert page.has_content?('If these match a userid, you will receive instructions on how to reset your password')
      assert_equal new_user_session_path, current_path
      assert_not_nil @user.reload.reset_password_token
    end
  end

  test 'an unidentified user should be able to request a password reset via sms' do
    ContactPoint::Sms.create!(user: @user, description: '(345) 123-4567', status: ContactPointState::VERIFIED)
    Devise.stubs(:friendly_token).returns('token')

    SmsSender.expects(:send_isolated_sms).with { |to, _, _| to.number == '13451234567' }

    visit new_user_password_path
    fill_in 'User ID', with: @user.uniqueid
    click_link 'Phone'
    #fill_in 'Phone number', with: '3451234567'
    page.execute_script("$('#phone_for_reset').val('(345) 123-4567')")
    click_link 'Text'

    synchronize do
      assert page.has_content?('If these match a userid, you will receive instructions on how to reset your password')
      assert_equal new_user_session_path, current_path
      assert_not_nil @user.reload.reset_password_token
    end
  end

  test 'an unidentified user should be able to request a password reset via voice' do
    Devise.stubs(:friendly_token).returns('token')
    User.expects(:fake_token).never
    User.expects(:fake_code).never

    contact_point = ContactPoint::Voice.create!(user: @user, description: '(345) 123-4567', status: ContactPointState::VERIFIED)

    visit new_user_password_path
    fill_in 'User ID', with: @user.uniqueid
    click_link 'Phone'
    #fill_in 'Phone number', with: '3451234567'
    page.execute_script("$('#phone_for_reset').val('(345) 123-4567')")
    click_link 'Voice'

    synchronize { assert page.has_content?('To finish the process, you must call') }

    voice_reset_code = @user.reload.voice_reset_code
    assert find('.voice-reset-code').has_content?(voice_reset_code)
    assert_equal voice_password_path('token'), current_path
    assert_not_nil @user.reset_password_token
    assert_equal contact_point, @user.voice_reset_contact
    assert_not_nil @user.voice_reset_code

    click_link 'Reset password'

    assert page.has_content?('To finish the process, you must call')
    assert find('.voice-reset-code').has_content?(voice_reset_code)
    assert page.has_content?('You must first complete the validation process by calling to the corresponding phone number')
    assert_equal voice_password_path('token'), current_path
  end

  test 'an unidentified user should be able to request a password reset via voice and change the password after making the call' do
    Devise.stubs(:friendly_token).returns('token')
    User.expects(:fake_token).never
    User.expects(:fake_code).never

    contact_point = ContactPoint::Voice.create!(user: @user, description: '(345) 123-4567', status: ContactPointState::VERIFIED)

    visit new_user_password_path
    fill_in 'User ID', with: @user.uniqueid
    click_link 'Phone'
    #fill_in 'Phone number', with: '3451234567'
    page.execute_script("$('#phone_for_reset').val('(345) 123-4567')")
    click_link 'Voice'

    synchronize { assert page.has_content?('To finish the process, you must call') }

    voice_reset_code = @user.reload.voice_reset_code
    assert find('.voice-reset-code').has_content?(voice_reset_code)
    assert_equal voice_password_path('token'), current_path
    assert_not_nil @user.reset_password_token
    assert_equal contact_point, @user.voice_reset_contact
    assert_not_nil @user.voice_reset_code

    @user.reset_password_via_voice(@user.voice_reset_code)
    click_link 'Reset password'

    assert_equal edit_user_password_path, current_path
    assert_not_nil current_url['?reset_password_token=token']
  end

  test 'an unidentified user should be able to reset his password with a valid reset token' do
    ContactPoint::Sms.create!(user: @user, description: '(345) 123-4567', status: ContactPointState::VERIFIED)
    token = @user.send_reset_password_instructions(description: '(345) 123-4567', type: 'sms')
    old_password = @user.encrypted_password

    visit edit_user_password_path(reset_password_token: token)
    sleep(1)
    fill_in 'Password (at least 6 characters)', with: 'newpassword'
    fill_in 'Password confirmation', with: 'newpassword'
    click_button 'Change my password'

    assert page.has_content?('Your password was changed successfully. You are now signed in.')
    assert_equal contact_points_path, current_path
    assert_not_equal old_password, @user.reload.encrypted_password
  end

  def visit_login
    visit new_user_session_path
    find("#start_now_link").click 
  end
end