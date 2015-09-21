require 'test_helper'

class UserTest < ActiveSupport::TestCase

 	def setup
    super
 		@user = create_user
    @number = TwilioNumber.default_number
 	end

  should belong_to :default_org_resource
  should have_one :default_org

  should have_many :contact_points
  should have_many :organization_users
	should have_many(:organizations).through(:organization_users)
  should have_many(:received_line_items).through(:organizations)
  should have_many(:broadcasts).through(:organization_users)
  should have_many :mappings
  should have_many :phone_mappings
  should have_many :email_mappings
  should have_many :orgs_as_default

	should validate_presence_of :uniqueid
	should validate_uniqueness_of :uniqueid
	should validate_presence_of :name

  test "uniqueid should be less than 50 chars" do
		@user.uniqueid = token_of_length 51
		assert !@user.save
 	end

 	test "name should be less than 50 chars" do
		@user.name = token_of_length 51
		assert !@user.save
 	end

 	test "website should be less than 250 chars" do
		@user.website = token_of_length 251
		assert !@user.save
 	end

  #associations

 	test "it should belong to an organization" do
    assert_not_nil @user.organizations.first
 	end

 	test "it should belong to an organization_user" do
    assert_not_nil @user.organization_users
 	end

  test "it should have a default organization resource" do
    assert_not_nil @user.default_org_resource
  end

 	test 'it should have a default org' do
 		assert_not_nil @user.default_org
 	end

  test "its first organization_user org should be the user default_org" do
    assert_equal @user.organization_users.first.organization, @user.default_org
  end

  #naming stuff

  test "its default organization should have the user uniqueid" do
    assert_equal @user.organizations.first.uniqueid, @user.uniqueid
  end

  test "its default organization should have the user name" do
    assert_equal @user.organizations.first.name, @user.name
  end

  test "its default org resource should have the user name" do
    assert_equal @user.default_org_resource.name, @user.name
  end

  test "its resource from the default org resource should have the user name" do
    assert_equal @user.default_org_resource.resource.name, @user.name
  end

  test "its resource from the default org resource should have the user uniqueid" do
    assert_equal @user.default_org_resource.resource.uniqueid, @user.uniqueid
  end

  test "its first organization_user should have the user name" do
    assert_equal @user.organization_users.first.name, @user.name
  end

  test "its default_org_resource should have the user.resource_name if provided" do
    u = create_user(uniqueid: 'u2', resource_name: 'Dana')
    assert_equal u.default_org_resource.name, u.resource_name
  end

  test "its default_org_resource resource should have the user.resource_name if provided" do
    u = create_user(uniqueid: 'u2', resource_name: 'Dana')
    assert_equal u.default_org_resource.resource.name, u.resource_name
  end

  test "its default_org_resource resource should have the user.resource_uniqueid if provided" do
    u = create_user(uniqueid: 'u2', resource_uniqueid: 'resourceuid')
    assert_equal u.default_org_resource.resource.uniqueid, u.resource_uniqueid
  end

  #save conditions

  test "it shouldnt be save if its organization_user isnt valid" do
    User.create  name: 'user', uniqueid: 'user', password: 'password'
    user = User.create  name: 'user', uniqueid: 'user', password: 'password'

    assert !user.persisted?
    assert !user.organization_users.first.persisted?
  end

  test "it shouldnt be save if its default org resource isnt valid too" do
    User.create  name: 'user', uniqueid: 'user', password: 'password'
    user = User.create  name: 'user', uniqueid: 'user', password: 'password'

    assert !user.persisted?
    assert !user.default_org_resource.persisted?
  end

  #finders

 	test 'it should respond to find_user' do
 		assert_respond_to User, :find_user
 	end

 	test 'find_user should return a user base on one or more contact_points' do
 		user = User.find_or_create_user( { email: "example@gmail.com" }, "example", organization_name: 'orgname', resource_name: "example")
 		email = user.contacts_email.first
    contact_point = { sms: "152000", email: email.description }

 		record_found = User.find_user(contact_point).first
 		assert_not_nil record_found
 		assert record_found.contact_points.include? email
 	end

 	test 'it should respond to find_or_create_user' do
 		assert_respond_to User, :find_or_create_user
 	end

 	test 'find_or_create_user should create new users' do
 		assert_not_nil User.find_or_create_user({email: "alfredo@gmail.com"}, "ascoppa", organization_name: 'orgname', resource_name: "alfredo")
 	end

 	test 'find_or_create_user should not create a user if already there' do
 		email = "ascoppa@gmail.com"
 		user1 = User.find_or_create_user({email: email}, "ascoppa", organization_name: 'orgname', resource_name: "alfredo")


 		assert_no_difference "User.count" do
 			user = User.find_or_create_user({email: email},"ascoppa", organization_name: 'orgname', resource_name: "alfredo")
 			assert_equal user1, user
 		end
 	end

 	test 'find_or_create_user shoud create contact_point if user is new' do
		assert_difference "ContactPoint.count" do
			user = User.find_or_create_user({sms: "(345) 654-5454"}, "pepe", organization_name: 'orgname', resource_name: "pepe")
      assert_equal user.contact_points, [ContactPoint.first]
		end
 	end

 	test 'find_or_create_user shoud not create contact_point if user is not new' do
		email = "ascoppa@gmail.com"
		User.find_or_create_user({email: email}, "ascoppa", organization_name: 'orgname', resource_name: "alfredo")

		assert_no_difference ["ContactPoint.count", "User.count"] do
			User.find_or_create_user({email: email},"ascoppa", organization_name: 'orgname', resource_name: "alfredo")
		end
 	end

  test 'find_or_create_user should create trusted contact points' do
    assert_difference "ContactPoint.count" do
      User.find_or_create_user({sms: "(345) 654-5454"}, "pepe", organization_name: 'orgname', resource_name: "pepe")
      assert ContactPoint.last.trusted?
    end
  end

  test 'find_or_create_user should create the organization with visibility public' do
    user = User.find_or_create_user( { sms: '(345) 666-6666' }, 'u', organization_name: 'orgname', resource_name: 'r')
    assert_equal 'public', user.default_org.visibility
  end

  test 'Resources created by find_or_create_user should use resource_name instead of user_name' do 
    user =  User.find_or_create_user({email: "alfredo@gmail.com"}, "Zen Spa", organization_name: 'orgname', resource_name: "dana")
    assert_equal "dana", user.resource_name
    assert_equal user.default_org_resource.resource.name, user.resource_name
  end

  test 'Resources created by find_or_create_user should use resource_uniqueid instead of user_uniqueid' do
    user =  User.find_or_create_user({email: "alfredo@gmail.com"}, "Zen Spa", organization_name: 'orgname', resource_name: "dana")
    assert_equal "alfredo-gmail-com-dana", user.resource_uniqueid
    assert_equal user.default_org_resource.resource.uniqueid, user.resource_uniqueid
  end

  test 'Default Org-Resources created by find_or_create_user should use resource_uniqueid instead of user_uniqueid' do
    user =  User.find_or_create_user({email: "alfredo@gmail.com"}, "Zen Spa", organization_name: 'orgname', resource_name: "dana")
    assert_equal "dana", user.resource_name
    assert_equal user.default_org_resource.name, user.resource_name
  end

  #others

  test 'matching_mappings should return the phone mappings for a given number' do
    PhoneMapping.any_instance.stubs(:generate_code)
    number = TwilioNumber.default_number
    m = @user.phone_mappings.new(twilio_number: number)
    m.save(validate: false)
    @user.phone_mappings.new(twilio_number: TwilioNumber.create(number: '9999999')).save(validate: false)
    assert_equal [m], @user.matching_mappings(number)
  end

  test 'needs_code? should return true if there are more than one active mappings for a number' do
    PhoneMapping.any_instance.stubs(:generate_code)
    m = @user.phone_mappings.build(twilio_number: @number)
    m.save(validate: false)
    m = @user.phone_mappings.build(twilio_number: @number)
    m.save(validate: false)

    assert @user.needs_code?(@number.number)
  end

  test 'needs_code? should return false if there is only one active mapping for a number' do
    PhoneMapping.any_instance.stubs(:generate_code)
    m = @user.phone_mappings.build(twilio_number: @number)
    m.save(validate: false)

    assert !@user.needs_code?(@number.number)
  end

  test 'can_make_requests? should return true if the user has at least one verified phone number' do
    ContactPoint::Voice.create(user: @user, description: '13451231231', status: ContactPointState::VERIFIED)
    assert @user.can_make_requests?
  end

  test "can_make_requests? should return false if the user doesn't have one verified phone number" do
    assert !@user.can_make_requests?
  end

  test 'organization_user_for should return the OrganizationUser with the given organization_id' do
    org = Organization.create!(name: 'org-name', uniqueid: 'org-uniqueid')
    org.add_user(@user)
    org_user = OrganizationUser.find_by(user: @user, organization: org)
    assert_equal org_user, @user.organization_user_for(org.id)
  end

  test 'organization_user_for should return nil if no OrganizationUser is found for the given organization_id' do
    org = Organization.create!(name: 'org-name', uniqueid: 'org-uniqueid')
    org.add_user(@user)
    OrganizationUser.find_by(user: @user, organization: org)
    assert_nil @user.organization_user_for(org.id.succ)
  end

  test 'verified_phone should return the first verified voice or sms contact point' do
    ContactPoint::Sms.create!(user: @user, description: '13451111111')
    ContactPoint::Voice.create!(user: @user, description: '13451111111', status: ContactPointState::DISABLED)
    verified = ContactPoint::Sms.create!(user: @user, description: '13451111112', status: ContactPointState::VERIFIED)
    assert_equal verified, @user.verified_phone
  end

  test 'preferred_area_code should return the area code of the first verified_phone' do
    ContactPoint::Sms.create!(user: @user, description: '13451111111')
    assert_nil @user.preferred_area_code
    ContactPoint::Sms.create!(user: @user, description: '13451111112', status: ContactPointState::VERIFIED)
    assert_equal '345', @user.preferred_area_code
  end

  test 'manageable_organizations should return the organizations that the user can manage' do
    @user.update!(organization_users: [])
    o1 = Organization.create!(name: 'o1', uniqueid: 'o1')
    o1.add_user(@user)
    o1.organization_users.find_by(user: @user).update!(status: OrganizationUserState::TRUSTED)
    o2 = Organization.create!(name: 'o2', uniqueid: 'o2')
    o2.add_user(@user)
    o2.organization_users.find_by(user: @user).update!(status: OrganizationUserState::UNTRUSTED)
    assert_equal [o1], @user.manageable_organizations.to_a
  end

  test 'can_manage_organization? should return true if the organization user related to the organization given is trusted' do
    o1 = Organization.create!(name: 'o1', uniqueid: 'o1')
    o1.add_user(@user)
    o1.organization_users.find_by(user: @user).update!(status: OrganizationUserState::TRUSTED)
    assert @user.can_manage_organization?(o1)
  end

  test 'can_manage_organization? should return false if the organization user related to the organization given is untrusted' do
    o1 = Organization.create!(name: 'o1', uniqueid: 'o1')
    o1.add_user(@user)
    o1.organization_users.find_by(user: @user).update!(status: OrganizationUserState::UNTRUSTED)
    assert !@user.can_manage_organization?(o1)
  end

  test 'find_or_create_org should create an org if it cant find one with the given name' do
    assert_difference '@user.organizations.count' do
      created_org = @user.find_or_create_org('Organization 1')
      assert_equal @user, created_org.default_user
      assert_equal 'Organization 1', created_org.name
      assert_equal 'public', created_org.visibility
    end
  end

  test 'find_or_create_org should not create an org if already there' do
    org = @user.default_org

    assert_no_difference 'Organization.count' do
      new_org = @user.find_or_create_org(org.name)
      assert_equal org, new_org
    end
  end

  test 'find_or_create_org should use id_generator to handle name collisions' do
    o = Organization.new(name: 'org_name', uniqueid: 'org_name')
    o.save!(validate: false)

    assert_difference '@user.organizations.count' do
      new_org = @user.find_or_create_org('org_name')
      assert_equal 'org-name', o.uniqueid
      assert_equal 'org-name1', new_org.uniqueid
    end
  end

  test 'set_default_user should be caller after_create' do
    u = User.new(name: 'u', uniqueid: 'u', password: 'password')
    u.expects(:set_default_user)
    u.save!
  end

  test 'set_default_user should set the default_user of its default_org to self if it is empty' do
    u = create_user(uniqueid: 'u')
    u.default_org.update!(default_user: nil)
    assert_nil u.default_org.default_user
    u.send(:set_default_user)
    assert_equal u, u.default_org.default_user
  end

  test 'set_default_user should do nothing if the default_user of its default_org is not empty' do
    u = create_user(uniqueid: 'u')
    u2 = create_user(uniqueid: 'u2')
    u.default_org.update!(default_user: u2)
    assert_equal u2, u.default_org.default_user
    u.send(:set_default_user)
    assert_equal u2, u.default_org.default_user
  end

  test 'build_organization_resource should be called before validation' do
    u = User.new
    u.expects(:build_organization_resource)
    u.valid?
  end

  test 'build_organization_user should be called before validation' do
    u = User.new
    u.expects(:build_organization_user)
    u.valid?
  end

  test 'build_organization_user should not be called before validation if without_org is true' do
    u = User.new(without_org: true)
    u.expects(:build_organization_user).never
    u.valid?
  end

  test 'normalize_login_information should be called before save' do
    u = User.new(name: 'name', uniqueid: 'uniqueid', password: 'password')
    u.expects(:normalize_login_information)
    u.save
  end

  test 'destroy_organizations should be called before destroy' do
    u = create_user(name: 'u2', uniqueid: 'u2')
    u.expects(:destroy_organizations)
    u.destroy
  end

  test 'destroy_organizations should not be called if skip_destroy_organizations is true' do
    u = create_user(name: 'u2', uniqueid: 'u2', skip_destroy_organizations: true)
    u.expects(:destroy_organizations).never
    u.destroy
  end

  test 'managed_resources should return a collection of resources accessed by user through the orgs it can manage' do
    assert_difference '@user.reload.managed_resources.size' do
      # creating a new org and new org-resource with accesses for @user
      org = Organization.create_with_user({name: 'new org', uniqueid: 'new-org'}, @user)
      OrganizationResource.find_or_create_within_org(org, 'new resource')
    end
  end

  test 'managed_org_resources should return a collection of org-resources accessed by user through the orgs it can manage' do
    @user.save
    assert_difference '@user.reload.managed_org_resources.size' do
      # creating a new org and new org-resource with accesses for @user
      org = Organization.create_with_user({name: 'new org', uniqueid: 'new-org'}, @user)
      OrganizationResource.find_or_create_within_org(org, 'new resource')
    end
  end

  test 'voice_number should return the preferred_voice number if there is one' do
    @user.expects(:preferred_voice).returns(ContactPoint::Voice.new(description: '13451111111'))
    assert_equal '13451111111', @user.voice_number
  end

  test 'voice_number should return the number of the first trusted or verified voice CP if there is no preferred_voice' do
    @user.stubs(:preferred_voice).returns(nil)
    cp1 = ContactPoint::Voice.new(description: '13451111111', status: ContactPointState::UNVERIFIED)
    cp2 = ContactPoint::Voice.new(description: '13452222222', status: ContactPointState::TRUSTED)
    @user.contact_points = [cp1, cp2]
    assert_equal '13452222222', @user.voice_number
    cp1 = ContactPoint::Voice.new(description: '13451111111', status: ContactPointState::UNVERIFIED)
    cp2 = ContactPoint::Voice.new(description: '13452222222', status: ContactPointState::VERIFIED)
    @user.contact_points = [cp1, cp2]
    assert_equal '13452222222', @user.voice_number
    cp1 = ContactPoint::Voice.new(description: '13451111111', status: ContactPointState::UNVERIFIED)
    cp2 = ContactPoint::Voice.new(description: '13452222222', status: ContactPointState::DISABLED)
    @user.contact_points = [cp1, cp2]
    assert_nil @user.voice_number
  end

  test 'notifiable_contacts should return the preferred_contacts if there are any' do
    cp = ContactPoint.new
    @user.expects(:preferred_contacts).returns([cp])
    assert_equal [cp], @user.notifiable_contacts
  end

  test 'notifiable_contacts should return the trusted or verified contact points if there are no preferred_contacts and allow_unverified is false' do
    @user.expects(:preferred_contacts).returns([])
    c1 = ContactPoint::Sms.create!(user: @user, description: '13459876541', status: ContactPointState::UNVERIFIED)
    c2 = ContactPoint::Sms.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    c3 = ContactPoint::Sms.create!(user: @user, description: '13459876543', status: ContactPointState::DISABLED)
    c4 = ContactPoint::Sms.create!(user: @user, description: '13459876544', status: ContactPointState::TRUSTED)
    assert_equal [c2, c4], @user.notifiable_contacts.order(:description).to_a
  end

  test 'notifiable_contacts should return the enabled contact points if there are no preferred_contacts and allow_unverified is true' do
    @user.expects(:preferred_contacts).returns([])
    c1 = ContactPoint::Sms.create!(user: @user, description: '13459876541', status: ContactPointState::UNVERIFIED)
    c2 = ContactPoint::Sms.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    c3 = ContactPoint::Sms.create!(user: @user, description: '13459876543', status: ContactPointState::DISABLED)
    c4 = ContactPoint::Sms.create!(user: @user, description: '13459876544', status: ContactPointState::TRUSTED)
    assert_equal [c1, c2, c4], @user.notifiable_contacts(allow_unverified: true).order(:description).to_a
  end

  test 'preferred_contacts should return the notifiable contact points' do
    c1 = ContactPoint::Sms.create!(user: @user, description: '13459876541', status: ContactPointState::UNVERIFIED)
    c2 = ContactPoint::Sms.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    c3 = ContactPoint::Sms.create!(user: @user, description: '13459876543', status: ContactPointState::VERIFIED, notifications_enabled: false)
    assert !c1.notifiable?
    assert c2.notifiable?
    assert !c3.notifiable?
    assert_equal [c2], @user.preferred_contacts.to_a
  end

  test 'preferred_voice should return the notifiable voice contact point' do
    c1 = ContactPoint::Voice.create!(user: @user, description: '13459876541', status: ContactPointState::UNVERIFIED)
    c2 = ContactPoint::Voice.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    c3 = ContactPoint::Voice.create!(user: @user, description: '13459876543', status: ContactPointState::VERIFIED, notifications_enabled: false)
    c4 = ContactPoint::Sms.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    assert !c1.notifiable?
    assert c2.notifiable?
    assert !c3.notifiable?
    assert c4.notifiable?
    assert_equal c2, @user.preferred_voice
  end

  test 'ensure_preferred_voice should do nothing if it has a preferred_voice' do
    ContactPoint::Voice.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    preferred = @user.preferred_voice
    @user.ensure_preferred_voice('-1')
    assert_equal preferred, @user.preferred_voice
  end

  test 'ensure_preferred_voice should set a preferred_voice if there is not one already' do
    cp = ContactPoint::Voice.create!(user: @user, description: '13451111111', status: ContactPointState::VERIFIED)
    cp.disable_notifications
    assert_nil @user.preferred_voice
    @user.ensure_preferred_voice('-1')
    assert_equal cp, @user.preferred_voice
  end

  test 'sorted_preferred_contacts should return the preferred_contacts ordered by type desc' do
    c1 = ContactPoint::Sms.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    c2 = ContactPoint::Voice.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED)
    c3 = ContactPoint::Email.create!(user: @user, description: 'something@something.com', status: ContactPointState::VERIFIED)
    assert_equal [c1, c2, c3], @user.preferred_contacts.order(:id).to_a
    assert_equal [c2, c1, c3], @user.sorted_preferred_contacts.to_a
  end

  test 'create_mappings should create an EmailMapping if there is any notifiable email contact' do
    li = raw_line_item
    ContactPoint::Email.create!(user: @user, description: 'mail@mail.com', status: ContactPointState::VERIFIED)
    assert_difference('EmailMapping.count') do
      @user.create_mappings(li, true)
      created_mapping = EmailMapping.last
      assert_equal @user, created_mapping.user
      assert_equal li, created_mapping.entity
    end
  end

  test 'create_mappings should not create an EmailMapping if there is not any notifiable email contact' do
    assert_no_difference('EmailMapping.count') { @user.create_mappings(LineItem.new, true) }
  end

  test 'create_mappings should create a PhoneMapping if there is any notifiable phone contact' do
    li = raw_line_item
    ContactPoint::Voice.create!(user: @user, description: '13451111111', status: ContactPointState::VERIFIED)
    assert_difference('PhoneMapping.count') do
      @user.create_mappings(li, true)
      created_mapping = PhoneMapping.last
      assert_equal @user, created_mapping.user
      assert_equal li, created_mapping.entity
    end
  end

  test 'create_mappings should not create a PhoneMapping if there is not any notifiable phone contact' do
    assert_no_difference('PhoneMapping.count') { @user.create_mappings(LineItem.new, true) }
  end

  test 'create_mappings should not create a PhoneMapping if include_phone is false' do
    ContactPoint::Voice.create!(user: @user, description: '13451111111', status: ContactPointState::VERIFIED)
    assert_no_difference('PhoneMapping.count') { @user.create_mappings(LineItem.new, false) }
  end

  test 'avoid_default_org should do nothing if the organization given is not its default organization' do
    o = create_organization
    old_default_org = @user.default_org
    @user.avoid_default_org(o)
    assert_equal old_default_org, @user.default_org
  end

  test 'avoid_default_org should update its default org resource to another one avoiding the organization given' do
    resource = create_resource
    o2 = create_organization
    org_resource = create_organization_resource(o2, resource)
    o2.add_user(@user)

    old_org_resource = @user.default_org_resource
    @user.avoid_default_org(@user.default_org)
    assert_equal org_resource, @user.default_org_resource
  end
end