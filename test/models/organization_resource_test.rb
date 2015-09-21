require 'test_helper'

class OrganizationResourceTest < ActiveSupport::TestCase
	should validate_presence_of :organization
	should validate_presence_of :resource
	should validate_presence_of :name

	should validate_uniqueness_of :name

	should belong_to :organization
	should belong_to :resource
	should have_many :line_items
	should have_many :users_as_default

	test "name length should at least be 50" do 
		organization_resource = OrganizationResource.new 
		organization_resource.organization = Organization.new
		organization_resource.resource = Resource.new
		
		organization_resource.name = token_of_length 51

		assert !organization_resource.valid?, organization_resource.errors.messages
	end

	test "it should respond to find_or_create_within_org" do
		assert_respond_to OrganizationResource, :find_or_create_within_org
	end

	test 'find_or_create_within_org should create a new resource within a user default org if it cant find one' do
		sms = "15005550010"
		user = User.find_or_create_user({sms: sms}, 'username', organization_name: 'orgname', resource_name: 'Resource1')

		assert_difference ['OrganizationResource.count', 'Resource.count'] do 
			OrganizationResource.find_or_create_within_org(user.default_org, "Resource2")
		end

		assert_equal user.default_org.organization_resources, [OrganizationResource.first, OrganizationResource.last]
	end

	test 'find_or_create_within_org should NOT create a new resource within a user default org if it can find one' do
		sms = "15005550010"
		resource_name = "Resource1"
		user = User.find_or_create_user({sms: sms}, 'username', organization_name: 'orgname', resource_name: resource_name)

		assert_no_difference ['OrganizationResource.count', 'Resource.count','Organization.count'] do 
			OrganizationResource.find_or_create_within_org(user.default_org, resource_name)
		end

		assert_equal user.default_org.organization_resources, [OrganizationResource.first]
	end

	test 'find_or_create_within_org should use id_generator to handle name collisions' do
		sms = "15005550010"
		user = User.find_or_create_user({sms: sms}, 'username', organization_name: 'orgname', resource_name: "Resource")

		org_resource1 = OrganizationResource.find_or_create_within_org(user.default_org, "Resource-1")
		org_resource2 = OrganizationResource.find_or_create_within_org(user.default_org, "Resource 1")

		assert_equal '15005550010-resource-2', org_resource2.resource.uniqueid
		assert_not_equal org_resource2, org_resource1
		assert org_resource2.valid?
	end

	test "It should respond to resource_default_unique_id" do
		assert_respond_to OrganizationResource, :resource_default_unique_id
	end

	#business="Zen Spa", resource="Dana" -> id="zenspadana"
	test "resource_default_unique_id should be a combination of org_uid and resource_name if both are present" do
		org_uid = "zen-spa"
		resource_name = "Dana"
		assert_equal "zen-spa-dana", OrganizationResource.resource_default_unique_id(org_uid, resource_name)
	end

	#business="Zen Spa", resource="" -> id="zenspaany"
	test "resource_default_unique_id should be equals to org_uid-anyone if resource_name not present" do
    org_uid = "zen-spa"
		resource_name = nil
		assert_equal "zen-spa-anyone", OrganizationResource.resource_default_unique_id(org_uid, resource_name)
	end

	test "It should respond to " do
		assert_respond_to OrganizationResource, :resource_default_name
	end

	#resource="Dana" ->  name="Dana"
	test "resource_default_name should be equals to resource_name if it is present" do
		resource_name = "Dana"
		assert_equal "Dana", OrganizationResource.resource_default_name(resource_name)
	end

	#resource="" ->  name="anyone"
	test "resource_default_name should be equals to anyone if resource_name is not present" do
		resource_name = nil
		assert_equal "anyone", OrganizationResource.resource_default_name(resource_name)
  end

  test 'full_name should return name if its name is equal to the organization name' do
    org_res = OrganizationResource.new(name: 'name', organization: Organization.new(name: 'name'))
    assert_equal 'name', org_res.full_name
  end

  test 'full_name should return name from org_name if its name is different to the organization name' do
    org_res = OrganizationResource.new(name: 'name1', organization: Organization.new(name: 'name2'))
    assert_equal 'name1 from name2', org_res.full_name
  end

  test "can_be_unlinked_by? should check if author's params can destroy self object" do
    user1 = User.create!({name: 'lionel messi', uniqueid: 'lio-messi', password: 'abcd1234'})
    org  	= user1.default_org
    org_resource = user1.default_org_resource

    assert org_resource.can_be_unlinked_by?(user1)

    # creating another user and asserting he can not destroy org_resource since it's the default of another user
    user2 = User.create!({name: 'sergio aguero', uniqueid: 'el-kun', password: 'abcd1234'})
    assert_not org_resource.can_be_unlinked_by?(user2)

    # creating another default org-resource for user1 so now org_resource will not have any user with default
    user1.default_org_resource = OrganizationResource.create!(name: 'a new resource', organization: org, resource: Resource.create(name: 'a new resource'))
    user1.save
    assert org_resource.can_be_unlinked_by?(user1)
    assert org_resource.can_be_unlinked_by?(user2)
  end

end