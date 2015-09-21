require 'test_helper'

class Admin::ApplicationControllerTest < ActionDispatch::IntegrationTest
  test 'an unidentified visitor should not be able to enter the admin section' do
    visit admin_users_path

    assert_equal new_user_session_path, current_path
  end

  test 'a non admin user should not be able to enter the admin section' do
    enable_js
    fake_sign_in_user(admin: false)
    visit admin_users_path

    assert_equal '<html xmlns="http://www.w3.org/1999/xhtml"><head></head><body></body></html>', page.body
  end

  test 'an admin user should be able to enter the admin section' do
    enable_js
    fake_sign_in_user(admin: true)
    visit admin_users_path
    assert_equal admin_users_path, current_path
  end

  test 'an unidentified visitor should not see the admin links in the navbar' do
    visit root_path
    assert page.has_no_content?('Admin')
  end

  test 'a non admin user should not see the admin links in the navbar' do
    enable_js

    fake_sign_in_user(admin: false)
    visit root_path
    assert page.has_no_content?('Admin')
  end

  # test 'an admin user should see the admin links in the navbar' do
  #   enable_js

  #   fake_sign_in_user(admin: true)
  #   visit root_path
  #   assert page.has_content?('Admin')
  # end
end
