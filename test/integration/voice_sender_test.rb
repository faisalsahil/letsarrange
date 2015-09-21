require 'test_helper'

class VoiceSenderTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Voice.new(description: '13451234567', user: @user)
    @number = TwilioNumber.default_number
    PhoneMapping.any_instance.stubs(:generate_code)
  end

  test 'send_message should do nothing' do
    skip
    VoiceSender.send_message('something', 'something 2')
  end

  test 'send_verification should call create on outgoing_caller_ids of twilio' do
    @contact_point.save!(validate: false)
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)
    VoiceSender.stubs(:unverify_outgoing_caller)
    outgoing_caller_ids.expects(:create).with { |args| args[:phone_number] == @contact_point.number }.returns(Struct.new(:validation_code, :call_sid).new('123456', '123123123'))
    VoiceSender.expects(:contact_point_voice_verification_url)
    @contact_point.stubs(:update)
    VoiceSender.send_verification(@contact_point)
  end

  test 'send_verification should update the contact_point with the call_sid as confirmation_token' do
    @contact_point.save!(validate: false)
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)
    VoiceSender.stubs(:unverify_outgoing_caller)
    outgoing_caller_ids.stubs(:create).returns(Struct.new(:validation_code, :call_sid).new('123456', '123123123'))
    Rails.application.routes.url_helpers.stubs(:contact_point_voice_verification_url)
    @contact_point.expects(:update!).with { |args| args[:confirmation_token] == '123123123' }
    VoiceSender.send_verification(@contact_point)
  end

  test 'send_verification should unverify the number first' do
    @contact_point.save!(validate: false)
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)
    outgoing_caller_ids.stubs(:create).returns(Struct.new(:validation_code, :call_sid).new('123456', '123123123'))
    Rails.application.routes.url_helpers.stubs(:contact_point_voice_verification_url)
    @contact_point.stubs(:update)

    VoiceSender.expects(:unverify_outgoing_caller).with(@contact_point.number)
    VoiceSender.send_verification(@contact_point)
  end

  test 'unverify_outgoing_caller should fetch all the outgoing callers for the given number' do
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)

    outgoing_caller_ids.expects(:list).with(phone_number: '123456').returns([])
    VoiceSender.send(:unverify_outgoing_caller, '123456')
  end

  test 'unverify_outgoing_caller should delete the verified caller from twilio' do
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)
    caller = Object.new
    outgoing_caller_ids.stubs(:list).returns([caller])

    caller.expects(:delete)
    VoiceSender.send(:unverify_outgoing_caller, '123456')
  end

  test 'terminate_call should fetch the call by call_sid' do
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    calls = account.calls
    account.stubs(:calls).returns(calls)
    calls.expects(:get).with('123123123')
    VoiceSender.terminate_call('123123123')
  end

  test 'terminate_call should update the status of the call to completed' do
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    calls = account.calls
    account.stubs(:calls).returns(calls)
    call = Object.new
    calls.stubs(:get).returns(call)
    call.expects(:update).with { |args| args[:status] == 'completed' }
    VoiceSender.terminate_call('123123123')
  end

  test 'revoke_outgoing_caller should fetch the call by call_sid' do
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)
    outgoing_caller_ids.expects(:get).with('123123123')
    VoiceSender.revoke_outgoing_caller('123123123')
  end

  test 'revoke_outgoing_caller should delete the call' do
    client = TwilioApi.client
    TwilioApi.stubs(:client).returns(client)
    account = client.account
    client.stubs(:account).returns(account)
    outgoing_caller_ids = account.outgoing_caller_ids
    account.stubs(:outgoing_caller_ids).returns(outgoing_caller_ids)
    caller_id = Object.new
    outgoing_caller_ids.stubs(:get).returns(caller_id)
    caller_id.expects(:delete)
    VoiceSender.revoke_outgoing_caller('123123123')
  end

  test 'route_to_orgs should dial_mapping if there is only one mapping' do
    PhoneMapping.any_instance.stubs(:voice_number).returns('13451231231')
    @contact_point.save(validate: false)
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    VoiceSender.expects(:dial_mapping).with(mapping, @contact_point.number)
    VoiceSender.send(:route_to_orgs, @contact_point, @number, 0, 0)
  end

  test 'route_to_orgs should dial_mapping if there are more than one mapping and one of them matchs with the code' do
    PhoneMapping.any_instance.stubs(:voice_number).returns('13451231231')
    @contact_point.save(validate: false)
    mapping = @user.phone_mappings.new(twilio_number: @number, code: '1')
    mapping.save(validate: false)
    m2 = @user.phone_mappings.new(twilio_number: @number, code: '2')
    m2.save(validate: false)
    VoiceSender.expects(:dial_mapping).with(mapping, @contact_point.number)
    VoiceSender.send(:route_to_orgs, @contact_point, @number, 0, '1')
  end

  test 'route_to_orgs should list_options if there are more than one mapping and no code is given' do
    PhoneMapping.any_instance.stubs(:voice_number).returns('13451231231')
    @contact_point.save(validate: false)
    mapping = @user.phone_mappings.new(twilio_number: @number, code: '1')
    mapping.save(validate: false)
    m2 = @user.phone_mappings.new(twilio_number: @number, code: '2')
    m2.save(validate: false)
    VoiceSender.expects(:list_options).with([mapping, m2], 0)
    VoiceSender.send(:route_to_orgs, @contact_point, @number, 0, nil)
  end

  test 'route_to_orgs should list_options if there are more than one mapping and the code given is invalid' do
    PhoneMapping.any_instance.stubs(:voice_number).returns('13451231231')
    @contact_point.save(validate: false)
    mapping = @user.phone_mappings.new(twilio_number: @number, code: '1')
    mapping.save(validate: false)
    m2 = @user.phone_mappings.new(twilio_number: @number, code: '2')
    m2.save(validate: false)
    VoiceSender.expects(:list_options).with([mapping, m2], 0)
    VoiceSender.send(:route_to_orgs, @contact_point, @number, 0, 3)
  end

  test 'rescue_from should call say with the message related to the exception' do
    VoiceSender.expects(:say)
    VoiceSender.rescue_from(Twilio::NoReceiverError.new)
  end

  test 'matching_mappings should delegate to the contact point' do
    matched = PhoneMapping.new
    matched.stubs(:voice_number).returns('13451231231')
    @user.expects(:matching_mappings).with(@number).returns([matched])
    VoiceSender.send(:matching_mappings, @user, @number)
  end

  test 'matching_mappings should exclude mappings without a voice number to route to' do
    matched = PhoneMapping.new
    matched.expects(:voice_number).returns('13451231231')
    unroutable = PhoneMapping.new
    unroutable.expects(:voice_number).returns(nil)
    @user.stubs(:matching_mappings).with(@number).returns([matched, unroutable])
    assert_equal [matched], VoiceSender.send(:matching_mappings, @user, @number)
  end

  test 'matching_mappings should throw NoMappingsError if no mappings matches' do
    assert_raise(Twilio::NoMappingsError) { VoiceSender.send(:matching_mappings, @user, @number) }
    unroutable = PhoneMapping.new
    unroutable.stubs(:voice_number).returns(nil)
    @user.stubs(:matching_mappings).with(@number).returns([unroutable])
    assert_raise(Twilio::NoMappingsError) { VoiceSender.send(:matching_mappings, @user, @number) }
  end

  test "list_options should say an error message if it isn't the first try" do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    mapping.stubs(:resource_full_name).returns('resource at org')
    assert_nil VoiceSender.send(:list_options, [mapping], 1)[/<Say[^<]+We didn't recognize that code<\/Say>/]
    assert_not_nil VoiceSender.send(:list_options, [mapping], 2)[/<Say[^<]+We didn't recognize that code<\/Say>/]
  end

  test 'list_options should call mappings_menu for each try remaining' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    VoiceSender.expects(:mappings_menu).twice
    VoiceSender.send(:list_options, [mapping], 2)
  end

  test 'list_options should end with a closing message' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    VoiceSender.stubs(:mappings_menu)
    assert_not_nil VoiceSender.send(:list_options, [mapping], 2)[/<Say[^<]+Sorry you are having trouble. Please try again later. Goodbye.<\/Say>/]
  end

  test 'mappings_menu should give the user 10 seconds to enter the code' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    mapping.stubs(:resource_full_name).returns('resource at org')
    output = Twilio::TwiML::Response.new do |res|
      VoiceSender.send(:mappings_menu, res, [mapping], 1)
    end.text
    assert_not_nil output['Gather timeout="10"']
  end

  test 'mappings_menu should post to the inbound url with the try count' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    mapping.stubs(:resource_full_name).returns('resource at org')
    output = Twilio::TwiML::Response.new do |res|
      VoiceSender.send(:mappings_menu, res, [mapping], 1)
    end.text
    assert_not_nil output["action=\"#{ Rails.application.routes.url_helpers.communication_voice_inbound_path(try: 1) }\""]
  end

  test 'mappings_menu should list the name and code of each mapping' do
    mapping = @user.phone_mappings.new(twilio_number: @number, code: '1')
    mapping.save(validate: false)
    mapping.stubs(:resource_full_name).returns('resource1 at org1')
    mapping2 = @user.phone_mappings.new(twilio_number: @number, code: '2')
    mapping2.save(validate: false)
    mapping2.stubs(:resource_full_name).returns('resource2 at org2')
    output = Twilio::TwiML::Response.new do |res|
      VoiceSender.send(:mappings_menu, res, [mapping, mapping2], 1)
    end.text
    assert_not_nil output["For resource1 at org1, enter 1"]
    assert_not_nil output["For resource2 at org2, enter 2"]
  end

  test 'say should Say the given message followed by Goodbye' do
    assert_not_nil VoiceSender.send(:say, 'something')[/<Say[^<]+something. Goodbye.<\/Say>/]
  end

  test 'route_call should call route_to_password_reset if the twilio number is not reserved? and the caller is able_to_reset' do
    @number.expects(:reserved?).returns(false)
    @contact_point.save!(validate: false)
    ContactPoint::Voice.any_instance.stubs(:able_to_reset?).returns(true)
    VoiceSender.expects(:route_to_password_reset).with('try')
    VoiceSender.route_call(@number, @contact_point.number, 'try', 0)
  end

  test 'route_call should call route_to_orgs if the twilio number is not reserved? and the caller is not able_to_reset' do
    @number.expects(:reserved?).returns(false)
    @contact_point.save!(validate: false)
    ContactPoint::Voice.any_instance.stubs(:able_to_reset?).returns(false)
    VoiceSender.expects(:route_to_orgs).with(@contact_point, @number, 'try', 0)
    VoiceSender.route_call(@number, @contact_point.number, 'try', 0)
  end

  test 'route_call should call route_reserved if the twilio number is reserved?' do
    @number.expects(:reserved?).returns(true)
    VoiceSender.expects(:route_reserved).with(@number, @contact_point.number)
    VoiceSender.route_call(@number, @contact_point.number, 'try', 0)
  end

  test 'route_to_password_reset response should include Wrong validation code unles it is the first try' do
    assert_not_nil VoiceSender.route_to_password_reset(2)['Wrong validation code']
    assert_nil VoiceSender.route_to_password_reset(1)['Wrong validation code']
  end

  test 'route_to_password_reset response should have a gather for each remaining try' do
    assert_equal 3, VoiceSender.route_to_password_reset(1).scan('<Gather timeout="10" action="/communication/voice/reset_password?try=').length
    assert_equal 1, VoiceSender.route_to_password_reset(3).scan('<Gather timeout="10" action="/communication/voice/reset_password?try=').length
  end

  test 'route_to_password_reset should give instructions' do
    assert_not_nil VoiceSender.route_to_password_reset(3)['To finish the password reset process, please enter the code shown in the website followed by pound']
  end

  test 'after_password_reset should say that the identity has been verified' do
    assert_not_nil VoiceSender.after_password_reset['Your identity has been verified. You can now continue with the password reset process via the website']
  end

  test 'number_to_contact should return a enabled phone contact with the number given' do
    ContactPoint::Sms.new(number: '13451111111', status: ContactPointState::DISABLED).save!(validate: false)
    cp = ContactPoint::Voice.new(number: '13451111111')
    cp.save!(validate: false)
    assert_equal cp, VoiceSender.number_to_contact('13451111111')
  end

  test 'start_conference should raise NoReceiverError if the attendant given is nil' do
    assert_raise(Twilio::NoReceiverError) { VoiceSender.send(:start_conference, 'conference_id', nil, 'caller_id', caller_announcement: 'announcement') }
  end

  test 'start_conference should return join_conference' do
    time = Time.now
    Timecop.freeze(time) do
      VoiceSender.stubs(:wait_url).returns('waiturl.com')
      VoiceSender.stubs(:call_conference_participant).returns(Struct.new(:sid).new('sid'))
      VoiceSender.expects(:join_conference).with("conference_id-#{ time.to_i }", announcement: 'someone calling', startConferenceOnEnter: false, waitMethod: 'get', waitUrl: 'waiturl.com', dependant_sid: 'sid').returns('return value')
      VoiceSender.send(:start_conference, 'conference_id', 'attendant', 'caller_id', caller_announcement: 'someone calling')
    end
  end

  test 'start_conference should set wait_url for the conference' do
    VoiceSender.expects(:wait_url).returns('http://a.wait.url.com')
    VoiceSender.expects(:join_conference).with { |_, opts| opts[:waitUrl] == 'http://a.wait.url.com' }
    VoiceSender.stubs(:call_conference_participant).returns(Struct.new(:sid).new('sid'))
    VoiceSender.send(:start_conference, 'conference_id', 'attendant', 'caller_id', caller_announcement: 'someone calling')
  end

  test 'start_conference should call call_conference_participant' do
    time = Time.now
    Timecop.freeze(time) do
      VoiceSender.expects(:call_conference_participant).with("conference_id-#{ time.to_i }", 'attendant', 'caller_id', 'someone calling').returns(Struct.new(:sid).new('sid'))
      VoiceSender.send(:start_conference, 'conference_id', 'attendant', 'caller_id', called_announcement: 'someone calling')
    end
  end

  test 'join_conference should dial a conference' do
    assert_not_nil VoiceSender.send(:join_conference, 'conference_id', announcement: 'someone calling')['<Response><Say voice="alice">someone calling</Say><Dial timeLimit="300"><Conference startConferenceOnEnter="true" endConferenceOnExit="true" beep="false" waitUrl="">conference_id</Conference></Dial></Response>']
  end

  test 'join_conference should override the default options with the options given' do
    assert_not_nil VoiceSender.send(:join_conference, 'conference_id', announcement: 'someone calling', beep: true, endConferenceOnExit: false)['<Response><Say voice="alice">someone calling</Say><Dial timeLimit="300"><Conference startConferenceOnEnter="true" endConferenceOnExit="false" beep="true" waitUrl="">conference_id</Conference></Dial></Response>']
  end

  test 'join_conference should skip saying something if there is no announcement' do
    assert_not_nil VoiceSender.send(:join_conference, 'conference_id')['<Response><Dial timeLimit="300"><Conference startConferenceOnEnter="true" endConferenceOnExit="true" beep="false" waitUrl="">conference_id</Conference></Dial></Response>']
  end

  test 'join_conference should play a beep sound if on_enter_beep is true' do
    VoiceSender.stubs(:beep_url).returns('http://beep.url.com/beep.wav')
    assert_nil VoiceSender.send(:join_conference, 'conference_id', on_enter_beep: false)['<Play>http://beep.url.com/beep.wav</Play>']
    assert_not_nil VoiceSender.send(:join_conference, 'conference_id', on_enter_beep: true)['<Play>http://beep.url.com/beep.wav</Play>']
  end

  test 'join_conference should add a dial action to cancel the dependant call if a dependant sid is given' do
    assert_not_nil VoiceSender.send(:join_conference, 'conference_id', dependant_sid: 'aSID')['<Dial timeLimit="300" action="/communication/voice/cancel_call?sid_to_cancel=aSID">']
  end

  test 'call_conference_participant should call join_conference' do
    TwilioApi.stubs(:client).returns(stub(account: stub(calls: stub(create: nil))))
    VoiceSender.expects(:join_conference).with('conference_id', announcement: 'someone calling', on_enter_beep: true)
    VoiceSender.send(:call_conference_participant, 'conference_id', 'attendant', 'caller_id', 'someone calling')
  end

  test 'call_conference_participant should create an outbound call' do
    VoiceSender.stubs(:beep_url).returns('beep.url.com')
    calls = Object.new
    calls.expects(:create).with(url: "http://twimlets.com/echo?Twiml=%3C%3Fxml+version%3D%221.0%22+encoding%3D%22UTF-8%22%3F%3E%3CResponse%3E%3CSay+voice%3D%22alice%22%3Esomeone+calling%3C%2FSay%3E%3CPlay%3Ebeep.url.com%3C%2FPlay%3E%3CDial+timeLimit%3D%22300%22%3E%3CConference+startConferenceOnEnter%3D%22true%22+endConferenceOnExit%3D%22true%22+beep%3D%22false%22+waitUrl%3D%22%22%3Econference_id%3C%2FConference%3E%3C%2FDial%3E%3C%2FResponse%3E", to: 'attendant', from: 'caller_id')
    TwilioApi.stubs(:client).returns(stub(account: stub(calls: calls)))
    VoiceSender.send(:call_conference_participant, 'conference_id', 'attendant', 'caller_id', 'someone calling')
  end

  test 'call_conference should pass on_enter_beep as true if an announcement is present' do
    TwilioApi.stubs(:client).returns(stub(account: stub(calls: stub(create: nil))))
    VoiceSender.expects(:join_conference).with { |_, opts| opts[:on_enter_beep] }
    VoiceSender.send(:call_conference_participant, 'conference_id', 'attendant', 'caller_id', 'an announcement')
  end

  test 'call_conference should pass on_enter_beep as false if an announcement is not present' do
    TwilioApi.stubs(:client).returns(stub(account: stub(calls: stub(create: nil))))
    VoiceSender.expects(:join_conference).with { |_, opts| !opts[:on_enter_beep] }
    VoiceSender.send(:call_conference_participant, 'conference_id', 'attendant', 'caller_id', nil)
  end

  test 'anonymous_number? should return true if the callerId given is anonymous' do
    assert VoiceSender.anonymous_number?('')
    assert VoiceSender.anonymous_number?('266696687')
    assert VoiceSender.anonymous_number?('7378742833')
    assert VoiceSender.anonymous_number?('2562533')
    assert VoiceSender.anonymous_number?('8656696')
    assert !VoiceSender.anonymous_number?('13451231231')
  end

  test 'route_reserved should call start_conference' do
    TwilioApi.stubs(:buy_number).returns('15001111111')
    t = TwilioNumber.first
    ou = OrganizationUser.create!(name: 'ou_name', user: create_user, organization: create_organization)
    ContactPoint::Voice.create!(user: ou.user, number: '13451111111', status: ContactPointState::VERIFIED)
    r = Request.new(reserved_number: t, created_by: ou)
    r.save!(validate: false)
    VoiceSender.expects(:start_conference).with('reserved-bridge-13451234567', '13451111111', '15001111111', called_announcement: '3 4 5 1 2 3 4 5 6 7 calling')
    VoiceSender.send(:route_reserved, t, @contact_point.number)
  end

  test 'route_reserved should use annuncement as the called announcement' do
    t = TwilioNumber.first
    ou = OrganizationUser.create!(name: 'ou_name', user: create_user, organization: create_organization)
    ContactPoint::Voice.create!(user: ou.user, number: '13451111111', status: ContactPointState::VERIFIED)
    r = Request.new(reserved_number: t, created_by: ou)
    r.save!(validate: false)
    VoiceSender.expects(:start_conference).with { |_, _, _, options| options[:called_announcement]== 'the announcement' }
    VoiceSender.expects(:announcement).with(@contact_point.number, r).returns('the announcement')
    VoiceSender.send(:route_reserved, t, @contact_point.number)
  end

  test 'route_reserved should use caller_id_for_number to get the caller_id' do
    t = TwilioNumber.first
    ou = OrganizationUser.create!(name: 'ou_name', user: create_user, organization: create_organization)
    ContactPoint::Voice.create!(user: ou.user, number: '13451111111', status: ContactPointState::VERIFIED)
    r = Request.new(reserved_number: t, created_by: ou)
    r.save!(validate: false)
    VoiceSender.expects(:start_conference).with { |_, _, caller_id, _| caller_id == 'the caller_id' }
    t.expects(:caller_id_for_number).with(@contact_point.number).returns('the caller_id')
    VoiceSender.send(:route_reserved, t, @contact_point.number)
  end

  test 'route_reserved should set the conference id to reserved-bridge-number' do
    t = TwilioNumber.first
    ou = OrganizationUser.create!(name: 'ou_name', user: create_user, organization: create_organization)
    ContactPoint::Voice.create!(user: ou.user, number: '13451111111', status: ContactPointState::VERIFIED)
    r = Request.new(reserved_number: t, created_by: ou)
    r.save!(validate: false)
    VoiceSender.expects(:start_conference).with { |conference_id, _, _, _| conference_id == "reserved-bridge-13451234567" }
    VoiceSender.send(:route_reserved, t, @contact_point.number)
  end

  test 'route_reserved should get the request voice number as the attendant number' do
    t = TwilioNumber.first
    ou = OrganizationUser.create!(name: 'ou_name', user: create_user, organization: create_organization)
    ContactPoint::Voice.create!(user: ou.user, number: '13451111111', status: ContactPointState::VERIFIED)
    r = Request.new(reserved_number: t, created_by: ou)
    r.save!(validate: false)
    VoiceSender.expects(:start_conference).with { |_, attendant, _, _| attendant == '13451111111' }
    VoiceSender.send(:route_reserved, t, @contact_point.number)
  end

  test 'dial_mapping should call start_conference' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.expects(:voice_number).returns('13451231231')
    mapping.expects(:resource_full_name).returns('orgresource at org')
    org = Organization.new(name: 'org')
    mapping.stubs(:caller_info).returns(Caller.new(@number, OrganizationResource.new(organization: org, name: 'orgresource'), OrganizationUser.new(organization: org, name: 'orguser')))
    VoiceSender.expects(:start_conference).with('org-bridge-from', '13451231231', '15005550006', caller_announcement: 'Calling orgresource at org', called_announcement: 'orguser at org calling about orgresource')
    VoiceSender.send(:dial_mapping, mapping, 'from')
  end

  test 'dial_mapping should omit the called announcement if the mappings caller info does not have an organization user' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.expects(:voice_number).returns('13451231231')
    mapping.expects(:resource_full_name).returns('orgresource at org')
    mapping.stubs(:caller_info).returns(Caller.new(@number))
    VoiceSender.expects(:start_conference).with('org-bridge-from', '13451231231', '15005550006', caller_announcement: 'Calling orgresource at org', called_announcement: nil)
    VoiceSender.send(:dial_mapping, mapping, 'from')
  end

  test 'dial_mapping should use calling_announcement as the called announcement' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    mapping.stubs(:resource_full_name).returns('orgresource at org')
    org = Organization.new(name: 'org')
    org_user = OrganizationUser.new(organization: org, name: 'orguser')
    org_resource = OrganizationResource.new(organization: org, name: 'orgresource')
    mapping.stubs(:caller_info).returns(Caller.new(TwilioNumber.new(number: '111'), org_resource, org_user))
    VoiceSender.expects(:start_conference).with { |_, _, _, options| options[:called_announcement]== 'the announcement' }
    VoiceSender.expects(:calling_announcement).with(org_user, org_resource).returns('the announcement')
    VoiceSender.send(:dial_mapping, mapping, 'from')
  end

  test 'dial_mapping should use caller_info to get the caller_id and organization_user' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    mapping.stubs(:resource_full_name).returns('orgresource at org')
    org = Organization.new(name: 'org')
    org_user = OrganizationUser.new(organization: org, name: 'orguser')
    org_resource = OrganizationResource.new(organization: org, name: 'orgresource')
    mapping.expects(:caller_info).returns(Caller.new(TwilioNumber.new(number: '111'), org_resource, org_user))
    VoiceSender.expects(:calling_announcement).with(org_user, org_resource).returns('the announcement')
    VoiceSender.expects(:start_conference).with { |_, _, caller_id, _| caller_id == '111' }
    VoiceSender.send(:dial_mapping, mapping, 'from')
  end

  test 'dial_mapping should set the conference id to org-bridge-number' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:voice_number).returns('13451231231')
    mapping.stubs(:resource_full_name).returns('orgresource at org')
    mapping.stubs(:caller_info).returns(Caller.new(@number, OrganizationUser.new(organization: Organization.new(name: 'org name'), name: 'orguser name')))
    VoiceSender.expects(:start_conference).with { |conference_id, _, _, _| conference_id == "org-bridge-from" }
    VoiceSender.send(:dial_mapping, mapping, 'from')
  end

  test 'dial_mapping should get the mapping voice number as the attendant number' do
    mapping = @user.phone_mappings.new(twilio_number: @number)
    mapping.save(validate: false)
    mapping.stubs(:resource_full_name).returns('orgresource at org')
    mapping.stubs(:caller_info).returns(Caller.new(@number, OrganizationUser.new(organization: Organization.new(name: 'org name'), name: 'orguser name')))
    VoiceSender.expects(:start_conference).with { |_, attendant, _, _| attendant == '13451231231' }
    mapping.expects(:voice_number).returns('13451231231')
    VoiceSender.send(:dial_mapping, mapping, 'from')
  end

  test 'announcement should return Unknown caller calling about resource announcement if the caller is anonymous' do
    org_resource = OrganizationResource.new(organization: Organization.new(name: 'org'), name: 'resource')
    VoiceSender.expects(:resource_announcement).with(org_resource).returns('resource announcement')
    assert_equal 'Unknown caller calling about resource announcement', VoiceSender.send(:announcement, VoiceSender::ANONYMOUS_NUMBERS.first, Request.new(organization_resource: org_resource))
  end

  test 'announcement should return calling_announcement with the denormalized number if there is no organization user with the phone number given' do
    org_resource = OrganizationResource.new(name: 'resource', organization: Organization.new(name: 'organization'))
    r = Request.new(organization_resource: org_resource)
    assert_nil User.find_user(voice: '13459876543').first
    VoiceSender.expects(:calling_announcement).with('3459876543', org_resource).returns('someone calling about something')
    assert_equal 'someone calling about something', VoiceSender.send(:announcement, '13459876543', r)
  end

  test 'announcement should return calling_announcement with the organization user if there is an organization user with the phone number given' do
    old_user = @user
    line_item_with_assoc!

    @line_item.organization_resource.organization = Organization.new(uniqueid: 'org').tap { |o| o.save!(validate: false) }
    @line_item.save!(validate: false)
    caller_org_user = @line_item.requested_organization.add_user(old_user)
    @contact_point.save!(validate: false)
    VoiceSender.expects(:calling_announcement).with(caller_org_user, @line_item.request.organization_resource).returns('someone calling about something')
    assert_equal 'someone calling about something', VoiceSender.send(:announcement, @contact_point.number, @line_item.request)
  end

  test 'calling_announcement should return caller announcement calling calling if there is no organization resource given' do
    VoiceSender.expects(:caller_announcement).with('from').returns('someone')
    assert_equal 'someone calling', VoiceSender.send(:calling_announcement, 'from')
  end

  test 'calling_announcement should return caller announcement calling about resource announcement with organization if an organization resource is given and its org is not the same as the org user' do
    org1 = Organization.new(name: 'org1')
    org2 = Organization.new(name: 'org2')
    org_user = OrganizationUser.new(name: 'orguser', organization: org1)
    org_resource = OrganizationResource.new(name: 'orgresource', organization: org2)
    VoiceSender.expects(:caller_announcement).with(org_user).returns('someone')
    VoiceSender.expects(:resource_announcement).with(org_resource, skip_organization: false).returns('some resource')
    assert_equal 'someone calling about some resource', VoiceSender.send(:calling_announcement, org_user, org_resource)
  end

  test 'calling_announcement should return caller announcement calling about resource announcement without organization if an organization resource is given and its org is the same as the org user' do
    org1 = Organization.new(name: 'org1')
    org_user = OrganizationUser.new(name: 'orguser', organization: org1)
    org_resource = OrganizationResource.new(name: 'orgresource', organization: org1)
    VoiceSender.expects(:caller_announcement).with(org_user).returns('someone')
    VoiceSender.expects(:resource_announcement).with(org_resource, skip_organization: true).returns('some resource')
    assert_equal 'someone calling about some resource', VoiceSender.send(:calling_announcement, org_user, org_resource)
  end

  test 'caller_announcement should return the TTS caller full name if it is an organization user' do
    TextToSpeech.expects(:convert).with('orguser at org').returns('tts orguser at org')
    assert_equal 'tts orguser at org', VoiceSender.send(:caller_announcement, OrganizationUser.new(name: 'orguser', organization: Organization.new(name: 'org')))
  end

  test 'caller_announcement should return the TTS caller number if it is just a number' do
    TextToSpeech.expects(:convert).with('3451234567').returns('tts 3451234567')
    assert_equal 'tts 3451234567', VoiceSender.send(:caller_announcement, '3451234567')
  end

  test 'resource_announcement should return the TTS organization resource full name if skip organization is false' do
    TextToSpeech.expects(:convert).with('orgresource from org').returns('tts orgresource from org')
    assert_equal 'tts orgresource from org', VoiceSender.send(:resource_announcement, OrganizationResource.new(name: 'orgresource', organization: Organization.new(name: 'org')), skip_organization: false)
  end

  test 'resource_announcement should return the TTS organization resource name if skip organization is true' do
    TextToSpeech.expects(:convert).with('orgresource').returns('tts orgresource')
    assert_equal 'tts orgresource', VoiceSender.send(:resource_announcement, OrganizationResource.new(name: 'orgresource', organization: Organization.new(name: 'org')), skip_organization: true)
  end

  test 'wait_url should return the url for a twimlet that plays the phone calling sound' do
    prev_asset_host = ActionController::Base.asset_host
    ActionController::Base.asset_host = 'some.host.com'
    VoiceSender.instance_variable_set(:@wait_url, nil)
    wait_url = VoiceSender.send(:wait_url)
    ActionController::Base.asset_host = prev_asset_host
    assert_equal 'http://twimlets.com/echo?Twiml=%3C%3Fxml+version%3D%221.0%22+encoding%3D%22UTF-8%22%3F%3E%3CResponse%3E%3CPlay+loop%3D%220%22%3Ehttp%3Asome.host.com%2Fassets%2Fphone_calling.mp3%3C%2FPlay%3E%3C%2FResponse%3E', wait_url
  end

  test 'beep_url should return the url of the beep sound' do
    prev_asset_host = ActionController::Base.asset_host
    ActionController::Base.asset_host = 'some.host.com'
    beep_url = VoiceSender.send(:beep_url)
    ActionController::Base.asset_host = prev_asset_host
    assert_equal 'http:some.host.com/assets/beep.wav', beep_url
  end

  test 'cancel_call should return an empty response' do
    TwilioApi.stubs(:client).returns(stub(account: stub(calls: stub(get: stub(update: stub)))))
    assert_equal '<Response></Response>', VoiceSender.cancel_call('sid')
  end

  test 'cancel_call should set the status of the call to completed' do
    fetched_call = Object.new
    fetched_call.expects(:update).with(status: 'completed')
    TwilioApi.stubs(:client).returns(stub(account: stub(calls: stub(get: fetched_call))))
    VoiceSender.cancel_call('sid')
  end
end