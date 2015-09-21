require 'test_helper'

class Organizations::UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    enable_js
    @user1 = fake_sign_in_user({name: 'carlos bianchi', uniqueid: 'virrey'})
    @user2 = User.create!({ name: 'roman riquelme', uniqueid: 'crack', password: 'password' })

    @organization = Organization.create!(name: 'Club Boca Juniors', uniqueid: 'cabj', default_user: @user2)
    @organization.add_user(@user1, name: 'coach')
    @organization.add_user(@user2, name: 'midfield')
    @org_user1 = @organization.org_user_for(@user1)
    @org_user2 = @organization.org_user_for(@user2)
    visit organization_users_path(@organization)
  end

  test 'I should be able to see the list of users linked to the organization' do
    assert page.has_content?('carlos bianchi')
    assert page.has_content?('roman riquelme')
    assert page.has_content?('coach')
    assert page.has_content?('midfield')
  end

  test 'I should not be able to unlink current user from the organization' do
    # current user doesn't have the link to 'unlink'
    within "#organization_user_#{@org_user1.id}" do
      assert has_no_link?('unlink')
    end
  end

  test 'I should be able to unlink other users from organization' do
    within "#organization_user_#{@org_user2.id}" do
      page.evaluate_script('window.confirm = function() { return true; }')
      click_link('unlink')
    end

    assert_equal organization_users_path(@organization), current_path
    assert find("#msgbar").has_content?('User successfully unlinked')
  end

  test "it should change org's default user after unlink that user" do
    # default user is @user2
    assert_equal @organization.default_user, @user2
    within "#organization_user_#{@org_user2.id}" do
      page.evaluate_script('window.confirm = function() { return true; }')
      click_link('unlink')
    end

    # new default user should change
    assert_equal @organization.reload.default_user, @user1
  end

  test "I should be able to change the organization's default user" do
    # current default user doesn't have the link to set default since it's already the default
    within "#organization_user_#{@org_user2.id}" do
      assert has_no_link?('set default')
    end

    within "#organization_user_#{@org_user1.id}" do
      click_link('set default')
    end
    assert_equal organization_users_path(@organization), current_path
    assert find("#msgbar").has_content?('Default user successfully updated')

    # current default user NOW should have the link to set default since it's been changed to other user
    within "#organization_user_#{@org_user2.id}" do
      assert has_link?('set default')
    end
  end

  test "I should be able to edit org-user's name and visibility" do
    within "#organization_user_#{@org_user2.id}" do
      click_link('edit')
    end
    assert_equal edit_organization_user_path(@organization,@org_user2), current_path
    find('#organization_user_name').set('retired')
    select('Private', from: 'organization_user_visibility')
    click_button('Update')

    assert_equal organization_users_path(@organization), current_path
    assert find("#msgbar").has_content?('Organization user successfully updated')
    within "#organization_user_#{@org_user2.id}" do
      assert has_content?('roman riquelme')
      assert has_content?('retired')
      assert has_content?('private')
    end
    assert_equal @org_user2.reload.name, 'retired'
    assert @org_user2.reload.private?
  end

  test "I should be able to link with existing users" do
    User.create!({ name: 'lionel messi', uniqueid: 'messi', password: 'password' })
    org_users_size = @organization.users.size
    click_link 'Link new user'
    assert_equal new_organization_user_path(@organization), current_path

    user_picker = find('.selectize-control.user_uniqueid input')
    user_picker.set('messi')
    sleep(2)
    user_picker.native.send_keys :enter
    click_button 'Add'

    assert_equal organization_users_path(@organization), current_path
    assert find("#msgbar").has_content?('New user successfully linked')
    assert page.has_content?('lionel messi')
    assert_equal (org_users_size + 1), @organization.reload.users.size
  end

  test 'I should be able to set as trusted an untrusted user' do
    untrusted_org_user = @user2.organization_user_for(@organization)
    untrusted_org_user.status = OrganizationUserState::UNTRUSTED
    untrusted_org_user.save!(validate: false)
    org_user_container = "#organization_user_#{ untrusted_org_user.id }"
    visit organization_users_path(@organization)

    assert untrusted_org_user.untrusted?
    assert find(org_user_container).has_content?('Status: untrusted')
    within org_user_container do
      page.evaluate_script('window.confirm = function() { return true; }')
      click_link 'set as trusted'
    end
    assert find(org_user_container).has_content?('Status: trusted')
    assert untrusted_org_user.reload.trusted?
  end
end