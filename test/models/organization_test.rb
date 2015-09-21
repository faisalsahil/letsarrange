require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
	def setup
    super
 		@organization = Organization.create uniqueid: "org1", name: "orgName"
 	end

	should validate_presence_of :name
	should validate_presence_of :uniqueid
	should validate_uniqueness_of :uniqueid

  should have_many :organization_users
  should have_many(:users).through(:organization_users)

  should have_many :organization_resources
  should have_many(:resources).through(:organization_resources)
  should have_many(:received_line_items).through(:organization_resources)

  should have_many :requests
  should have_many(:line_items).through(:requests)

	should belong_to :default_user

	test "uniqueid length should at least be 50" do 
		@organization.uniqueid = token_of_length 51
		assert !@organization.valid?, @organization.errors.messages
	end

	test "name length should at least be 50" do 
		@organization.name = token_of_length 51
		assert !@organization.valid?, @organization.errors.messages
	end

	test 'it should respond to add_user' do
 		assert_respond_to Organization.new, :add_user
 	end

 	test 'add_user should create and add an org_user to this org' do
 		user = create_user

 		assert_difference 'OrganizationUser.count' do 
 			org_user = @organization.add_user user
 			assert_equal [org_user],@organization.organization_users
 		end
 	end

 	test 'add_user shouldnt add a user twice' do
    user = create_user
		org_user = @organization.add_user user

 		assert_no_difference 'OrganizationUser.count' do 
 			org_user2 = @organization.add_user user
 			assert_equal [org_user],@organization.organization_users
 			assert_equal org_user, org_user2
 		end
  end

  test 'add_user should create an org_user with the extra attrs given' do
    user = create_user

    assert_difference 'OrganizationUser.count' do
      org_user = @organization.add_user(user, name: 'custom name', status: OrganizationUserState::UNTRUSTED)
      assert_equal 'custom name', org_user.name
      assert_equal OrganizationUserState::UNTRUSTED, org_user.status
    end
  end

  test 'private? should return true if the visibility is private' do
    assert Organization.new(visibility: 'private').private?
  end

  test 'private? should return false if the visibility is not private' do
    assert !Organization.new(visibility: 'public').private?
  end

  test 'public? should return true if it is not private?' do
    org = Organization.new
    org.expects(:private?).returns(false)
    assert org.public?
  end

  test 'private? should return false if it is private?' do
    org = Organization.new
    org.expects(:private?).returns(true)
    assert !org.public?
  end

  test 'create_by_name_and_user should create an organization with the name and default user given' do
    user = create_user
    organization = Organization.create_by_name_and_user!('org_name', user)

    assert_equal [user], organization.users
    assert_equal user, organization.default_user
    assert_equal 'org_name', organization.name
    assert organization.private?
  end

  test 'has_user? should return true if the user belongs to the organization' do
    user = create_user
    @organization.add_user(user)
    assert @organization.has_user?(user)
  end

  test 'has_user? should return false if the user does not belong to the organization' do
    user = create_user
    assert !@organization.has_user?(user)
  end

  test 'default_organization_user should return the organization user that links the org with its default_user' do
    u = create_user
    @organization.add_user(u)
    @organization.update!(default_user: u)
    assert_equal u, @organization.default_user
    assert_equal u.id, @organization.default_organization_user.user_id
    assert_equal @organization.id, @organization.default_organization_user.organization_id
  end

  test 'avoid_default_user should do nothing if the user given is not its default user' do
    u = create_user
    old_default_user = @organization.default_user
    @organization.avoid_default_user(u)
    assert_equal old_default_user, @organization.default_user
  end

  test 'avoid_default_user should update its default user to another one avoiding the user given' do
    u1 = create_user
    u2 = create_user
    @organization.add_user(u1)
    @organization.add_user(u2)
    @organization.update!(default_user: u1)
    @organization.avoid_default_user(u1)
    assert_equal u2, @organization.default_user
  end
end
