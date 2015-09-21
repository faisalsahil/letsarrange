require 'test_helper'

class OrganizationUserTest < ActiveSupport::TestCase
  should belong_to :organization
  should belong_to :user
  should have_many :broadcasts

	should validate_presence_of :organization
	should validate_presence_of :user
	should validate_presence_of :name

	should validate_uniqueness_of :name

  test "name length should at least be 50" do
		organization_user = OrganizationUser.new 
		organization_user.organization = Organization.new
		organization_user.user = User.new
		
		organization_user.name = token_of_length 51

		assert !organization_user.valid?, organization_user.errors.messages
	end

	test 'full_name should return the name if it is the same as the organization name' do
    org_user = OrganizationUser.new(name: 'name')
    org_user.stubs(:organization).returns(Organization.new(name: 'name'))
    assert 'name', org_user.full_name
  end

  test 'full_name should return org_user_name at org_name if its name is different to the organization name' do
    org_user = OrganizationUser.new(name: 'name')
    org_user.stubs(:organization).returns(Organization.new(name: 'name2'))
    assert 'name at name2', org_user.full_name
  end

  test 'shares_organization? should return true if the given user belongs to its organization' do
    user1 = create_user(name: '1', uniqueid: '1')
    user2 = create_user(name: '2', uniqueid: '2')
    org = Organization.create!(name: 'org-name', uniqueid: 'org-uniqueid')
    org.add_user(user1)
    org.add_user(user2)
    org_user = user1.organization_users.find_by(organization: org)
    assert org_user.shares_organization?(user2)
  end

  test 'shares_organization? should return false if the given user does not belong to its organization' do
    user1 = create_user(name: '1', uniqueid: '1')
    user2 = create_user(name: '2', uniqueid: '2')
    org = Organization.create!(name: 'org-name', uniqueid: 'org-uniqueid')
    org.add_user(user1)
    org_user = user1.organization_users.find_by(organization: org)
    assert !org_user.shares_organization?(user2)
  end

  test 'it should be created as trusted by default' do
    ou = OrganizationUser.new
    ou.save!(validate: false)
    assert ou.trusted?
  end

  test 'trusted? should return true if its status is trusted' do
    assert OrganizationUser.new(status: OrganizationUserState::TRUSTED).trusted?
  end

  test 'trusted? should return false if its status is not trusted' do
    assert !OrganizationUser.new(status: OrganizationUserState::UNTRUSTED).trusted?
  end

  test 'untrusted? should return true if its status is untrusted' do
    assert OrganizationUser.new(status: OrganizationUserState::UNTRUSTED).untrusted?
  end

  test 'untrusted? should return true if its status is not untrusted' do
    assert !OrganizationUser.new(status: OrganizationUserState::TRUSTED).untrusted?
  end

  test 'trusted scope should include trusted organization users' do
    o1 = OrganizationUser.new(status: OrganizationUserState::TRUSTED)
    o1.save!(validate: false)
    o2 = OrganizationUser.new(status: OrganizationUserState::UNTRUSTED)
    o2.save!(validate: false)
    assert_equal [o1], OrganizationUser.trusted.to_a
  end

  test 'set_as_trusted should set its status to trusted' do
    ou = OrganizationUser.new(status: OrganizationUserState::UNTRUSTED)
    ou.save!(validate: false)
    assert !ou.trusted?
    ou.set_as_trusted
    assert ou.trusted?
  end
end
