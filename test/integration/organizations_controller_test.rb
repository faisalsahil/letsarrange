require 'test_helper'

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    enable_js
    @user = fake_sign_in_user
    @organization = Organization.create!(name: 'org-name', uniqueid: 'org-uid', default_user: @user)
    @organization.add_user(@user, name: 'custom org-user name')
    visit organizations_path
  end

  test 'as a User I should be able to see the list of my organizations' do
    within "#organizations" do
      assert has_content?('org-name')
      assert has_content?('org-uid')
      assert has_content?('private')
      assert has_content?('custom org-user name')
    end
  end

  test 'as a User I should be able to create a new organization' do
    click_link('Add organization')
    assert_equal new_organization_path, current_path

    find('#organization_name').set 'club banco popular'
    find('#organization_uniqueid').set 'bco-popular'
    find('#org_user_name').set 'ariel diaz'
    assert_difference("@user.organizations.count") do
      click_button('Create')
    end

    assert find("#msgbar").has_content?('The organization was successfully created')
    org = @user.organizations.last
    assert_equal org.name, 'club banco popular'
    assert_equal org.uniqueid, 'bco-popular'
    assert_equal org.org_user_for(@user).name, 'ariel diaz'
    assert org.private?
  end

  test 'as a User I should be able to edit org-name/org-id/org-user-name of any of my organizations' do
    within("#organization_#{ @organization.id }") { click_link('edit') }
    assert_equal edit_organization_path(@organization), current_path

    find('#organization_name').set 'club atletico boca juniors'
    find('#organization_uniqueid').set 'cabj'
    find('#org_user_name').set 'roman riquelme'
    click_button('Update')
    assert find("#msgbar").has_content?('The organization was successfully updated')
    assert_equal @organization.reload.name, 'club atletico boca juniors'
    assert_equal @organization.reload.uniqueid, 'cabj'
    assert_equal @organization.org_user_for(@user).name, 'roman riquelme'
  end

  test 'as a User I should be able to delete my organizations' do
    before = @user.organizations.size
    within("#organization_#{ @organization.id }") do
      page.evaluate_script('window.confirm = function() { return true; }')
      click_link('delete')
    end

    after = @user.organizations.size
    assert_equal before, after+1
    assert find("#msgbar").has_content?('The organization was successfully deleted')
  end

  test 'as a User I should not be able to delete my LAST organization' do
    # destroying @organization so we leave @user with access to only 1 org
    @organization.destroy!
    assert_equal @user.reload.organizations.size, 1

    # reload organizations page
    visit organizations_path
    within("#organization_#{ @user.reload.default_org.id }") do
      assert page.has_no_link?('delete')
    end
  end

  test 'as a User I should not be able to delete an organization which is the default of other user' do
    # creating a new user with @organization as default org
    @resource     = Resource.create!({ name: 'roman riquelme', uniqueid: 'roman' })
    @org_resource = @organization.add_resource(@resource, 'brain')
    @user2 = User.create!({name: 'lio messi',
                           uniqueid: 'lio-messi',
                           password: 'abcd1234',
                           password_confirmation: 'abcd1234'})

    @organization.add_user(@user2, name: 'crack')
    @user2.default_org_resource = @org_resource
    @user2.save

    assert_equal @user2.reload.default_org, @organization

    # reload organizations page and assert that @organization can't be deleted
    visit organizations_path
    within("#organization_#{ @organization.id }") do
      assert page.has_no_link?('delete')
    end
  end

  test 'as a User I should be able to change the visibility of my organization' do
    within "#organization_#{ @organization.id }" do
      click_link('change')
      assert has_content?('public')
      assert @organization.reload.public?
    end
  end

  test 'the user should not be able to change the visibility of an organization he cant manage' do
    organization = @user.organizations.first
    assert organization.private?

    assert @user.can_manage_organization?(organization)
    @user.organization_users.find_by(organization: organization).update!(status: OrganizationUserState::UNTRUSTED)
    assert !@user.can_manage_organization?(organization)

    visit organizations_path

    within "#organization_#{ organization.id }" do
      assert has_content?(organization.name)
      assert has_content?('private')
      assert has_no_content?('change')
    end
  end

  test 'as a User I should be able to unlink myself from an untrusted organization' do
    u2 = create_user
    untrusted_org = u2.organizations.first
    untrusted_org.add_user(@user, name: 'name at untrusted', status: OrganizationUserState::UNTRUSTED)

    visit organizations_path

    assert_not_nil @user.organization_user_for(untrusted_org.id)
    within("#organization_#{ untrusted_org.id }") do
      page.evaluate_script('window.confirm = function() { return true; }')
      assert_no_difference 'Organization.count' do
        click_link('unlink')
      end
    end
    assert_nil @user.organization_user_for(untrusted_org.id)
    assert find("#msgbar").has_content?('You were successfully unlinked from the organization')
  end

  test 'as a User I should be able to unlink myself and destroy an untrusted organization if I am its only user' do
    untrusted_org = create_organization(default_user: @user)
    untrusted_org.add_user(@user, name: 'name at untrusted', status: OrganizationUserState::UNTRUSTED)

    visit organizations_path

    assert_not_nil @user.organization_user_for(untrusted_org.id)
    within("#organization_#{ untrusted_org.id }") do
      page.evaluate_script('window.confirm = function() { return true; }')
      assert_difference('Organization.count', -1) do
        click_link('unlink')
      end
    end
    assert_nil Organization.find_by(id: untrusted_org.id)
    assert find("#msgbar").has_content?('You were successfully unlinked from the organization')
  end
end