module TestHelpers 
	def token_of_length chars
		token = ''
		chars.times { token += 'x'}
		token
	end

	def create_resource name_length=5
		Resource.create name: token_of_length(name_length)
	end

	def create_organization_resource organization,resource, name_length=5
		OrganizationResource.create organization: organization,
									resource: resource,
									name: token_of_length(name_length)
  end

  def fake_sign_in_user(args = {})
    u = create_user(args)

    visit new_user_session_path
    find("#start_now_link").click

    fill_in 'user_login', with: u.uniqueid
    fill_in 'user_password', with: u.password
    within '#sign_in_form_container' do
      click_button('Sign in')
    end
    sleep(1)

    u
  end

  #Use this if you must use rack-test (for example to assert status code)
  def fake_sign_in_without_js(args={})
    u = create_user(args)
    visit new_user_session_path+"?page=2"
    fill_in 'User ID (e.g. jamieblack72)', with: 'user'
    fill_in 'Password (at least 8 characters)', with: 'password'
    click_button "Sign in"
    u
  end

  def line_item_with_assoc!
    @user = create_user(sms_sent_to_user_state: SmsSentToUserState::NEVER, name: 'Zen Spa', uniqueid: 'zen-spa',
                          resource_name: "dana", resource_uniqueid: "zen-spa-dana")

    orguser = @user.organization_user_for(@user.default_org_resource.organization)
    request = Request.create!(organization_resource: @user.default_org_resource,
                              created_by: orguser,
                              time_zone: 'UTC',
                              earliest_start: Time.now,
                              finish_by: Time.now,
                              length: '0:00')

    resource = Resource.new  name: "Dana", uniqueid: "dana"
    resource.save(validate: false)

    requested_org = create_organization
    receiver = create_user(name: 'receiver', uniqueid: 'receiver')
    created_for = requested_org.add_user(receiver)

    organization_resource = OrganizationResource.new(resource: resource, organization: requested_org, name: "Dana")
    organization_resource.save(validate: false)

    earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    finish_by = Time.parse('10 Jan 2014 03:00:00 PM UTC')

    @line_item = LineItem.new earliest_start: earliest_start, finish_by: finish_by,
                              length: "1:00", description: "Massage",
                              location: "My Place", offer: '$50',
                              organization_resource: organization_resource,
                              created_for: created_for, request: request

    @line_item.save(validate: false)
  end

  def enable_js
    Capybara.current_driver = Capybara.javascript_driver
  end

  def create_user(args = {})
    name = SecureRandom.hex(10)
    User.create!( { name: name, uniqueid: name, password: 'password' }.merge(args))
  end

  def create_organization(args = {})
    name = SecureRandom.hex(10)
    Organization.create!( { name: name, uniqueid: name }.merge(args))
  end

  def raw_line_item
    LineItem.new.tap do |li|
      li.stubs(:populate_from_parent)
      li.save!(validate: false)
    end
  end
end

class CatchAll
  def method_missing(*args)
  end
end