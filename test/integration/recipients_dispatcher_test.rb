require 'test_helper'

class RecipientsDispatcherTest < ActiveSupport::TestCase

  test 'it should respond to dispatch' do
    assert_respond_to RecipientsDispatcher, :dispatch
  end

  test 'it should fail if it doesnt have at least one contact point' do 
     recipient_attributes = { sms: "", business_name: "Zen Spa", 
                                  resources: { "0"=>{name: "Dana", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    assert_raises ArgumentError do
      RecipientsDispatcher.dispatch recipient_attributes
    end                                   
  end

  test 'it should fail if it doesnt have at least one resource' do 
     recipient_attributes = { sms: "15005550010", business_name: "Zen Spa", 
                                  resources: {}}

    assert_raises ArgumentError do
      RecipientsDispatcher.dispatch recipient_attributes
    end                                   
  end

  test 'It should create new users' do 
    recipient_attributes = { sms: "(500) 555-0010", business_name: "Zen Spa",
                                 resources: { "0"=>{name: "Dana", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    assert_difference ["User.count", "OrganizationUser.count"] do
      RecipientsDispatcher.dispatch recipient_attributes
    end

    assert_equal "(500) 555-0010", User.last.name
    assert_equal "(500) 555-0010", OrganizationUser.last.name
    assert_equal "15005550010", User.last.uniqueid
  end

  test 'It should return one recipient per resource' do 
    recipient_attributes = { sms: "15005550010", business_name: "Zen Spa", 
                                   resources: { "0"=>{name: "Dana", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    recipients = RecipientsDispatcher.dispatch recipient_attributes

    assert_equal 2, recipients.size

    assert_equal "Zen Spa", recipients.first[:business_name]
    assert_equal "Dana", recipients.first[:resource_name]
    assert_equal "15005550010", recipients.first[:sms]
    assert_equal "recipient_key_1", recipients.first[:key]
    assert_nil recipients.first[:voice]
    assert_nil recipients.first[:email]

    assert_equal "Zen Spa", recipients[1][:business_name]
    assert_equal "Mariano", recipients[1][:resource_name]
    assert_equal "15005550010", recipients[1][:sms]
    assert_equal "recipient_key_2", recipients[1][:key]
    assert_nil recipients[1][:voice]
    assert_nil recipients[1][:email]
  end

  test 'It should set organization_resource_id' do 
    recipient_attributes = { sms: "15005550010", business_name: "Zen Spa", 
                                 resources: { "0"=>{name: "Dana", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }


    recipients = RecipientsDispatcher.dispatch recipient_attributes
    
    recipients.each do |recipient|
      assert_equal OrganizationResource.where(name: recipient[:resource_name]).first.id, recipient[:organization_resource_id]
    end
  end

  test 'It should set created_for_id to the OrganizationUser created when contacted via sms' do
    assert_nil OrganizationUser.first
    recipient_attributes = { sms: "15005550010", business_name: "Zen Spa",
                             resources: { "0"=>{name: "Dana", key: "recipient_key_1"},
                                          "1"=>{name: "Mariano", key: "recipient_key_2"}} }


    recipients = RecipientsDispatcher.dispatch recipient_attributes

    recipients.each do |recipient|
      assert_equal OrganizationUser.last.id, recipient[:created_for_id]
    end
  end

  test 'It should set created_for_id to the OrganizationUser created when contacted via voice' do
    assert_nil OrganizationUser.first
    recipient_attributes = { voice: "15005550010", business_name: "Zen Spa",
                             resources: { "0"=>{name: "Dana", key: "recipient_key_1"},
                                          "1"=>{name: "Mariano", key: "recipient_key_2"}} }


    recipients = RecipientsDispatcher.dispatch recipient_attributes

    recipients.each do |recipient|
      assert_equal OrganizationUser.last.id, recipient[:created_for_id]
    end
  end

  test 'It should set created_for_id to the OrganizationUser created when contacted via email' do
    assert_nil OrganizationUser.first
    recipient_attributes = { email: "myemail@mydomain.com", business_name: "Zen Spa",
                             resources: { "0"=>{name: "Dana", key: "recipient_key_1"},
                                          "1"=>{name: "Mariano", key: "recipient_key_2"}} }


    recipients = RecipientsDispatcher.dispatch recipient_attributes

    recipients.each do |recipient|
      assert_equal OrganizationUser.last.id, recipient[:created_for_id]
    end
  end

  test 'It should set created_for_id to the default_organization_user of the organization when contacted via organization uniqueid' do
    existing_org = create_user(name: 'existing org', uniqueid: 'existing-org').organizations.first
    recipient_attributes = { organization_uniqueid: "existing-org",
                             resources: { "0"=>{name: "Dana", key: "recipient_key_1"},
                                          "1"=>{name: "Mariano", key: "recipient_key_2"}} }


    recipients = RecipientsDispatcher.dispatch recipient_attributes

    recipients.each do |recipient|
      assert_equal existing_org.default_organization_user.id, recipient[:created_for_id]
    end
  end

  test 'It should create new resources and attach them to the given org' do 
    recipient_attributes = { sms: '(500) 555-0010', business_name: "Zen Spa",
                                  resources: { "0"=>{name: "Dana", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    assert_difference ['Resource.count', 'OrganizationResource.count'], 2 do
      RecipientsDispatcher.dispatch recipient_attributes
    end

    org = Organization.where(name: "Zen Spa").last

    assert_equal org.organization_resources.to_a, OrganizationResource.all

    #naming stuff
    assert_equal "Dana", OrganizationResource.first.name
    assert_equal "Dana", Resource.first.name
    assert_equal "15005550010-dana", Resource.first.uniqueid

    assert_equal "Mariano", OrganizationResource.last.name
    assert_equal "Mariano", Resource.last.name
    assert_equal "15005550010-mariano", Resource.last.uniqueid

    assert_equal "(500) 555-0010", User.last.name
    assert_equal "15005550010", User.last.uniqueid
  end

  test 'It should be able to bootstrap a recipient with no org_name' do
    recipient_attributes = { sms: '(500) 555-0010',
                                  resources: { "0"=>{name: "Dana_85", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    assert_difference ['User.count'] do 
      assert_difference ['Resource.count', 'OrganizationResource.count'],2 do 
        RecipientsDispatcher.dispatch recipient_attributes
      end
    end

    #resources
    assert_equal "Dana_85", OrganizationResource.first.name
    assert_equal "Dana_85", Resource.first.name
    assert_equal "15005550010-dana-85", Resource.first.uniqueid

    assert_equal "Mariano", OrganizationResource.last.name
    assert_equal "Mariano", Resource.last.name
    assert_equal "15005550010-mariano", Resource.last.uniqueid

    #orgs
    assert_equal '(500) 555-0010', User.last.default_org.name
    assert_equal "15005550010", User.last.default_org.uniqueid

    #user
    assert_equal "(500) 555-0010", User.last.name
    assert_equal "15005550010", User.last.uniqueid
  end

  test 'It should be able to bootstrap a recipient with no resource_name ' do 
    recipient_attributes = { sms: '(500) 555-0010', business_name: "Zen Spa",
                                  resources: { "0"=>{key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    assert_difference ['User.count'] do 
      assert_difference ['Resource.count', 'OrganizationResource.count'],2 do 
        RecipientsDispatcher.dispatch recipient_attributes
      end
    end

    #resources
    assert_equal "anyone", OrganizationResource.first.name
    assert_equal "anyone", Resource.first.name
    assert_equal "15005550010-anyone", Resource.first.uniqueid

    assert_equal "Mariano", OrganizationResource.last.name
    assert_equal "Mariano", Resource.last.name
    assert_equal "15005550010-mariano", Resource.last.uniqueid

    #orgs
    assert_equal "Zen Spa", User.last.default_org.name
    assert_equal "15005550010", User.last.default_org.uniqueid

    #user
    assert_equal "(500) 555-0010", User.last.name
    assert_equal "15005550010", User.last.uniqueid
  end

  test 'It should be able to bootstrap a recipient from a phone with no resource name and no org_name' do 
    recipient_attributes = {  sms: '(500) 555-0010',
                            resources: { "0"=>{name: "anyone", key: "recipient_key_1"}, 
                                         "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    assert_difference ['User.count'] do 
      assert_difference ['Resource.count', 'OrganizationResource.count'],2 do 
        RecipientsDispatcher.dispatch recipient_attributes
      end
    end

    #resources
    assert_equal "anyone", OrganizationResource.first.name
    assert_equal "anyone", Resource.first.name
    assert_equal "15005550010-anyone", Resource.first.uniqueid

    assert_equal "Mariano", OrganizationResource.last.name
    assert_equal "Mariano", Resource.last.name
    assert_equal "15005550010-mariano", Resource.last.uniqueid

    #orgs
    assert_equal '(500) 555-0010', User.last.default_org.name
    assert_equal "15005550010", User.last.default_org.uniqueid

    #user
    assert_equal '(500) 555-0010', User.last.name
    assert_equal "15005550010", User.last.uniqueid
  end

   test 'It should be able to bootstrap a recipient from an email with no resource name and no org_name' do 
    recipient_attributes = {
        email: "alfredo@zenspa.com",
        resources: { "0"=>{name: "anyone", key: "recipient_key_1"},
                     "1"=>{name: "Mariano", key: "recipient_key_2"}
        }
    }

    assert_difference ['User.count'] do 
      assert_difference ['Resource.count', 'OrganizationResource.count'],2 do 
        RecipientsDispatcher.dispatch recipient_attributes
      end
    end

    #resources
    assert_equal "anyone", OrganizationResource.first.name
    assert_equal "anyone", Resource.first.name
    assert_equal "alfredo-zenspa-com-anyone", Resource.first.uniqueid

    assert_equal "Mariano", OrganizationResource.last.name
    assert_equal "Mariano", Resource.last.name
    assert_equal "alfredo-zenspa-com-mariano", Resource.last.uniqueid

    #orgs
    assert_equal 'alfredo@zenspa.com', User.last.default_org.name
    assert_equal "alfredo-zenspa-com", User.last.default_org.uniqueid
  end

  test "it should add existing resources to existing orgs" do 
    User.find_or_create_user({sms: "15005550010"},'user', organization_name: 'Zen Spa',resource_name: 'dana')

    recipient_attributes = { sms: "(500) 555-0010", business_name: "Zen Spa",
                                    resources: { "0"=>{name: "Mariano", key: "recipient_key_1"}, 
                                                 "1"=>{name: "dana", key: "recipient_key_2"}} }

    assert_difference ["OrganizationResource.count", "Resource.count"] do
      RecipientsDispatcher.dispatch recipient_attributes
    end

    assert_equal "Mariano", OrganizationResource.last.name
    assert_equal "Mariano", Resource.last.name
    assert_equal "15005550010-mariano", Resource.last.uniqueid
  end

  test 'It should add existing users to new orgs' do 
    User.find_or_create_user( { sms: "15005550010" }, 'alfredo', organization_name: 'alfredoorg', resource_name: 'alfredores')
    recipient_attributes = {
        sms: "15005550010", business_name: 'org2',
        resources: { "0" => { name: 'res1', key: "recipient_key_1" },
                     "1" => { name: 'res2', key: "recipient_key_2" }
        }
    }

    assert_no_difference "User.count" do
      assert_difference ["OrganizationUser.count", "Organization.count"] do
        RecipientsDispatcher.dispatch recipient_attributes
      end
    end

    assert_equal [OrganizationUser.last], Organization.last.organization_users
    assert_equal 2, Organization.last.organization_resources.count
  end

  test 'It should treat (none) as nil for business_name' do
    recipient_attributes = { sms: "(500) 555-0010", business_name: "(none)",
                                 resources: { "0"=>{name: "Dana 85", key: "recipient_key_1"}, 
                                              "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    RecipientsDispatcher.dispatch recipient_attributes

    assert_equal "(500) 555-0010", Organization.last.name
    assert_equal "15005550010", Organization.last.uniqueid
  end

  test 'It should treat anyone as anyone for resource_name' do
    recipient_attributes = { sms: "(500) 555-0010", business_name: "Zen Spa",
                                      resources: { "0"=>{name: "anyone", key: "recipient_key_1"}, 
                                                    "1"=>{name: "Mariano", key: "recipient_key_2"}} }

    RecipientsDispatcher.dispatch recipient_attributes
    
    assert_equal "anyone", OrganizationResource.first.name
    assert_equal "anyone", Resource.first.name
    assert_equal "15005550010-anyone", Resource.first.uniqueid

    assert_equal "Zen Spa", User.last.default_org.name
    assert_equal "15005550010", User.last.default_org.uniqueid
  end
end