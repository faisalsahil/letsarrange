  require 'test_helper'

class Organizations::ResourcesControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    enable_js
    @user = fake_sign_in_user({name: 'rodolfo donofrio', uniqueid: 'gallina'})

    @resource1 = Resource.create!({ name: 'marcelo barovero', uniqueid: 'trapito' })
    @resource2 = Resource.create!({ name: 'leonel vangioni', uniqueid: 'piri' })

    @organization = Organization.create!(name: 'Club Atletico River Plate', uniqueid: 'carp', default_user: @user)
    @organization.add_user(@user, name: 'president')

    @org_resource1 = @organization.add_resource(@resource1,'goalkeeper')
    @org_resource2 = @organization.add_resource(@resource2,'defender')

    @user.default_org_resource = @org_resource1
    @user.save

    visit organization_resources_path(@organization)
  end

  test 'I should be able to see the list of resources linked to the organization' do
    assert page.has_content?('marcelo barovero')
    assert page.has_content?('goalkeeper')
    assert page.has_content?('leonel vangioni')
    assert page.has_content?('defender')
  end

  test 'I should be able to unlink resources from organization' do
    assert_equal @user.default_org_resource, @org_resource1
    within "#organization_resource_#{@org_resource1.id}" do
      page.evaluate_script('window.confirm = function() { return true; }')
      click_link('unlink')
    end

    assert_equal organization_resources_path(@organization), current_path
    assert find("#msgbar").has_content?('Resource successfully unlinked')
    # user's default org-resource should be updated
    assert_equal @user.reload.default_org_resource, @org_resource2
  end

  test 'I should not be able to unlink the last org-resource the user has access' do
    # creating another user that has @org_resource2 as its default
    @user2 = User.create!({name: 'another-user', uniqueid: 'another-user', password: 'password'})
    @organization.add_user(@user2, name: 'minister')
    @user2.default_org_resource = @org_resource2
    @user2.save
    # reload index page
    visit organization_resources_path(@organization)
    # it shouldn't have a link to 'unlink' action
    within "#organization_resource_#{@org_resource2.id}" do
      assert page.has_no_link?('unlink')
    end
  end

  test "I should be able to edit org-resource's name and visibility" do
    within "#organization_resource_#{@org_resource2.id}" do
      click_link('edit')
    end
    assert_equal edit_organization_resource_path(@organization,@org_resource2), current_path
    find('#organization_resource_name').set('midfield')
    select('Private', from: 'organization_resource_visibility')
    click_button('Update')

    assert_equal organization_resources_path(@organization), current_path
    assert find("#msgbar").has_content?('Organization resource successfully updated')
    within "#organization_resource_#{@org_resource2.id}" do
      assert has_content?('leonel vangioni')
      assert has_content?('midfield')
      assert has_content?('private')
    end
    assert_equal @org_resource2.reload.name, 'midfield'
    assert @org_resource2.reload.private?
  end


  test "I should be able to change current user's default org-resource" do
    # org-resource1 don't have the link to set default since it's already the default for the current user
    within "#organization_resource_#{@org_resource1.id}" do
      assert has_no_link?('set default')
    end

    within "#organization_resource_#{@org_resource2.id}" do
      click_link('set default')
    end
    assert_equal organization_resources_path(@organization), current_path
    assert find("#msgbar").has_content?("User's default org-resource successfully updated")

    # org-resource1 NOW should have the link to set default since it's been changed
    within "#organization_resource_#{@org_resource1.id}" do
      assert has_link?('set default')
    end
  end

  test "I should be able to add new resources" do
    org_resources_size = @organization.resources.size
    click_link 'Add new resource'
    assert_equal new_organization_resource_path(@organization), current_path

    find('#resource_name').set('Manu Lanzini')

    click_button 'Add'

    assert_equal organization_resources_path(@organization), current_path
    assert find("#msgbar").has_content?('New resource successfully added')
    assert page.has_content?('Manu Lanzini')
    assert_equal (org_resources_size + 1), @organization.reload.resources.size
  end

end