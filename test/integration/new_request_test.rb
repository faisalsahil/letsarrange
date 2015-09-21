require 'test_helper'

class NewRequestTest < ActionDispatch::IntegrationTest
  def setup
    super
    enable_js
  end

  #flow
  test "as a user I should be able to create new requests and add recipients to the request" do
    User.any_instance.stubs(:can_make_requests?).returns(true)
    fake_sign_in_user
    visit new_request_path

    add_recipient_by "phone","(211) 111-1111","Zen Spa", "Dana"
    assert find("#lineitems_recipients_list").has_content? "Dana from Zen Spa"
    submit_request
    sleep(1)
    assert page.has_content? "Dana from Zen Spa"
  end

  test "as a user I should be able to create new requests and set it's values" do
    User.any_instance.stubs(:can_make_requests?).returns(true)
    fake_sign_in_user
    visit new_request_path

    set_length '#request_page_1'
    set_dates '#request_page_1'

    earliest_start = earliest_start_hour
    finish_by = finish_by_hour
    earliest_start = earliest_start[0..-3] if earliest_start[-2..-1] == finish_by[-2..-1] #both are am or both are pm

    request_title = "The ultimate lesson at My place for 1:00 #{day} between #{ earliest_start }-#{ finish_by } (ideally #{ideal_day}#{ ideal_start_hour })"

    set_request_attributes set_schedule: false

    add_recipient_by "phone","(211) 111-1111","Zen Spa", "Dana"
    submit_request
    visit requests_path

    assert find(".request_list .request_title").has_content?(request_title),"The request title is wrong! Title expected: #{ request_title }. Actual title: #{ find(".request_list .request_title").text }"
  end

  test "as a user I should be able to customize recipients values" do
    User.any_instance.stubs(:can_make_requests?).returns(true)
    fake_sign_in_user(name: 'user', uniqueid: 'user')
    visit new_request_path

    set_request_attributes set_schedule: false
    add_recipient_by "phone","(211) 111-1111","Zen Spa", "Dana"

    find(".goto_recipient").click
    assert find("p#recipient_customize_title").has_content? "Customize Dana from Zen Spa"

    set_length "#line_1"
    set_dates "#line_1"
    find("#line_1 .description").set "The worst lesson ever"
    find("#line_1 .comment").set "True story"

    earliest_start = earliest_start_hour
    finish_by = finish_by_hour
    earliest_start = earliest_start[0..-3] if earliest_start[-2..-1] == finish_by[-2..-1] #both are am or both are pm
    line_item_title = "[offered] Dana from Zen Spa: The worst lesson ever #{day} between #{ earliest_start }-#{ finish_by } (ideally #{ideal_day}#{ ideal_start_hour })"
    broadcast = "user: The worst lesson ever at My place with Dana for 1:00 #{day} between #{ earliest_start }-#{ finish_by } (ideally #{ideal_day}#{ ideal_start_hour }) offering $120 - True story"
    click_on "Save"

    submit_request

    assert find(".request-summary").has_content? "user: The ultimate lesson at My place for 1:00 offering $120"
    assert find(".line_item h2").has_content?(line_item_title), "The LI title is wrong! Title expected: #{ line_item_title }. Actual title: #{ find(".line_item h2").native.text }"
    assert has_content?(broadcast), "The broadcast is wrong! expected #{broadcast}. Actual broadcast #{ first(".broadcast").text }"
  end

  #by email
  test "as a user I should be able to add a recipient with no business_name" do
    visit new_request_path

    add_recipient_by "email", "bookings@zenspa.com","", "Dana", false
    assert find("#lineitems_recipients_list li").has_content? "Dana"
  end

  test "as a user I should be able to add a recipient with no resource_name" do
    visit new_request_path
    add_recipient_by "email", "bookings@zenspa.com","Zen Spa", "", false
    assert find("#lineitems_recipients_list li").has_content? "anyone from Zen Spa"
  end

  test "as a user I should be able to add a recipient with no resource_name and no business_name" do
    visit new_request_path
    add_recipient_by "email", "bookings@zenspa.com","", "", false
    assert find("#lineitems_recipients_list li").has_content? 'anyone'
  end

  test "adding a recipient by email without business_name and with several resources should add one recipient per resource" do
    visit new_request_path
    add_recipient_by "email", "bookings@zenspa.com","", "Dana,Bob",false
    assert all("#lineitems_recipients_list li")[0].has_content? "Bob"
    assert all("#lineitems_recipients_list li")[1].has_content? "Dana"
  end

  #phone

  test "adding a recipient by phone without business_name and with several resources should add one recipient per resource" do
    visit new_request_path
    add_recipient_by "phone","(211) 111-1111","", "Dana,Bob", false

    ["Bob", "Dana"].each_with_index do |resource, index|
        assert all("#lineitems_recipients_list li")[index].has_content? "#{resource}"
    end
  end

  #mod. tracking

  test "No field should be mark as dirty the first time a user view a recipient even when the request is blank" do
    visit new_request_path
    add_recipient_by "email", "bookings@zenspa.com","Zen Spa", "Dana"
    find(".goto_recipient").click
    assert !page.has_selector?(".has-changed")
  end

  test "No field should be mark as dirty the first time a user view a recipient" do
    visit new_request_path
    find('#request_offer').set '$120'
    find('#request_comment').set 'this is a comment'
    add_recipient_by "email", "bookings@zenspa.com","Zen Spa", "Dana"
    find(".goto_recipient").click
    assert !page.has_selector?(".has-changed")
  end

  test "As a user I should be able to see the differences between a recipient and the request" do
    visit new_request_path
    find('#request_offer').set '$120'
    find('#request_comment').set 'this is a comment'

    add_recipient_by "email", "bookings@zenspa.com","Zen Spa", "Dana"

    find(".goto_recipient").click

    assert page.has_no_selector?(".has-changed")

    find("#line_1 .comment").set "True story"
    find("#line_1 .offer").click

    sleep(1)
    assert page.has_selector?(".has-changed .comment")
  end

  test 'letsarrange.com/+13459999999 should add a recipient by phone automatically' do
    visit '/+13459999999'
    assert_equal '(345) 999-9999', find('.phone .contact_point').value

    find('.selectize-control.resources input').native.send_keys :return
    find(".contact_using_ckbox").click
    find(".add_recipient").click
    sleep(1)
    assert page.has_selector?('#request_page_1')

    first('.subnav .submenu_recipients').click
    assert first("#lineitems_recipients_list li").has_content?('anyone from (345) 999-9999')
  end

  test 'letsarrange.com/+email@email.com should add a recipient by email automatically' do
    visit '/+email@email.com'
    assert_equal 'email@email.com', find('.email .contact_point').value

    find('.selectize-control.resources input').native.send_keys :return
    find(".add_recipient").click
    sleep(1)
    assert page.has_selector?('#request_page_1')

    first('.subnav .submenu_recipients').click
    assert first("#lineitems_recipients_list li").has_content?('anyone from email@email.com')
  end

  test 'letsarrange.com/+org-uid should add a recipient by organization uniqueid automatically' do
    default_user = create_user
    Organization.create!(uniqueid: 'org-uid', name: 'name of organization', default_user: default_user).add_user(default_user)
    visit '/+org-uid'
    assert_equal 'name of organization (org-uid)', find('.organization .business_name.organizations_list .selectize-input').text

    find('.selectize-control.resources input').native.send_keys :return
    find(".add_recipient").click
    sleep(1)
    assert page.has_selector?('#request_page_1')

    first('.subnav .submenu_recipients').click
    assert first("#lineitems_recipients_list li").has_content?('anyone from name of organization')
  end

  test 'letsarrange.com/+org-uid-that-doesnt-exist should redirect to root' do
    visit '/+org-uid-that-doesnt-exist'
    assert_equal new_user_session_path, current_path
  end

  test "as a user with more than one org I should be able to create a new one on the fly with custom orguser name" do
    User.any_instance.stubs(:can_make_requests?).returns(true)
    user = fake_sign_in_user
    org  = create_organization(name: 'another org')
    create_organization_resource(org,create_resource)
    OrganizationUser.create_or_update_with(organization: org, user: user, name: user.name)
    visit new_request_path
    add_organization 'Zen Spa'

    # assert default orguser name is user's name
    orguser_picker = find('input.made_for_org_user_name')
    assert_equal orguser_picker.value, user.name

    # clear default orguser name and set a custom one
    40.times { orguser_picker.native.send_keys :backspace }
    orguser_picker.native.send_keys 'Dana from Zen Spa'

    # orguser_picker.native.send_keys :return
    first("#request_page_5 .back_page").click
    sleep(1)

    # assert org was created, name is the one defined and orguser was also created with custom name
    organizations = user.reload.organizations
    org     = organizations.last
    orguser = user.reload.organization_users.where(organization: org).first
    assert_equal organizations.size, 3
    assert_equal org.name, 'Zen Spa'
    assert_equal orguser.name, 'Dana from Zen Spa'
  end

  test "as a new user with only one org I should not be able to create orgs on the fly" do
    User.any_instance.stubs(:can_make_requests?).returns(true)
    user = fake_sign_in_user
    visit new_request_path
    first(".request_page_1.next_page").click
    page.has_no_selector?('.org_resource_info', visible: true)
  end


  def add_organization business_name
    first(".request_page_1.next_page").click
    business_picker = find('.selectize-control.made_for_organizations_list .selectize-input.full')

    unless business_name.blank?
      business_picker.click
      org_picker = find('.selectize-control.made_for_organizations_list input')
      40.times { org_picker.native.send_keys :backspace }
      org_picker.native.send_keys business_name
      org_picker.native.send_keys :return
    end
  end

  def add_recipient_by method, cp, business_name, resource_name, should_assert=true
    first('.subnav .submenu_recipients').click
    first(".request_page_2.next_page").click

    send "add_by_#{method}", cp

    business_picker = find('.selectize-control.business_name .selectize-input.full') #wait for it to become active

    unless business_name.blank?
      business_picker.click
      org_picker = find('.selectize-control.business_name input')
      7.times { org_picker.native.send_keys :backspace }
      org_picker.native.send_keys business_name
      org_picker.native.send_keys :return
    end

    resource_picker = find('.selectize-control.resources input')
    resource_picker.native.send_keys resource_name
    resource_picker.native.send_keys :return

    find(".contact_using_ckbox").click if method == "phone"
    find(".add_recipient").click

    sleep(1)

    if should_assert
      resources =  resource_name.split(",")
      assert page.all("#lineitems_recipients_list li").count == resources.size, "It should have #{resources.size} recipients"

      resources.reverse.each_with_index do |resource, index|
        assert all("#lineitems_recipients_list li")[index].has_content? "#{resource} from #{business_name}"
      end
    end
  end

  def add_by_phone phone
    find(".add_by_phone").click
    page.execute_script("$('.phone .contact_point').val('#{phone}')")
    find(".phone .lookup_btn").click
  end

  def add_by_email email
    click_on "Email"
    page.execute_script("$('.email .contact_point').val('#{email}')")
    find(".email .lookup_btn").click
  end

  def submit_request
    click_on "Send request"
    page.has_no_selector?('#loading', visible: true)
  end

  def day
    "today" #at least until we decide to change the day
  end

  def ideal_day
    day if day == "tomorrow "
  end

  def earliest_start_hour
    first(".earliest_start_control").value.split(" ").last
  end

  def ideal_start_hour
    first(".ideal_start_control").value.split(" ").last
  end

  def finish_by_hour
    first(".finish_by_control").value.split(" ").last
  end

  def view_request
    assert find("h1").has_content? "REQUESTS MADE"
    assert all(".request_list li").count == 1, "It should have one request"
    first(".request_list a").click
  end

  def set_request_attributes set_schedule: true
    if set_schedule
      set_length "#request_page_1"
      set_dates "#request_page_1"
    end

    find("#request_description").set "The ultimate lesson"
    find("#request_location").set "My place"
    find('#request_offer').set '$120'
    find('#request_comment').set 'this is a comment'
  end

  def set_dates container
    set_date_picker "#{container}", "earliest_start"
    set_date_picker "#{container}", "finish_by"
    set_date_picker "#{container}", "ideal_start"
  end

  def set_length container
    within("#{ container }") do
      find(".length_control").click
      find('.hour.active').click
      find('.minute.active').click
    end
  end

  def set_date_picker container, picker
    within("#{ container }") do
      find(".#{ picker }_control").click
      first(".hour:not(.disabled) > span:not(.disabled)").click
      first(".minute:not(.disabled) > span:not(.disabled)").click
    end
  end
end