require 'test_helper'

class RequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    Capybara.current_driver = Capybara.javascript_driver 
  end

  test 'a user should be able to create a new request if he has at least one verified phone number' do
    fake_sign_in_user
    User.any_instance.stubs(:can_make_requests?).returns(true)
    visit new_request_path

    assert_equal new_request_path, current_path
  end
end
