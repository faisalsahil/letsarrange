require 'test_helper'

class EmailMessageTest < ActiveSupport::TestCase
  def setup
    super
    line_item_with_assoc!

    Broadcast.any_instance.stubs(:send_messages)
    Broadcast.stubs(:create_with_user).returns(Broadcast.new)
  end

  should validate_presence_of :from
  should validate_presence_of :to
  should validate_presence_of :subject
  should validate_presence_of :body

  should belong_to :broadcast

  test 'it should have sid as alias of uid' do
    assert_equal 'uid', EmailMessage.attribute_aliases['sid']
  end

  test 'with_address scope should return the records that are linked to a broadcast and has the address given as from or to' do
    a = EmailMessage.create!(body: 'body', subject: 'subject', broadcast_id: 123, from: 'some_address', to: 'some_to')
    b = EmailMessage.create!(body: 'body', subject: 'subject', broadcast_id: 1234, from: 'some_from', to: 'some_address')

    EmailMessage.create!(body: 'body', subject: 'subject', broadcast_id: 12345, from: 'some_from', to: 'some_to')
    EmailMessage.create!(body: 'body', subject: 'subject', from: 'some_address', to: 'some_to')
    EmailMessage.create!(body: 'body', subject: 'subject', from: 'some_from', to: 'some_address')
    EmailMessage.create!(body: 'body', subject: 'subject', from: 'some_from', to: 'some_to')

    assert_equal [a, b], EmailMessage.with_address('some_address').to_a
  end

  test 'rebuild_broadcast should fetch the mapping' do
    e = EmailMessage.new
    e.stubs(:email_to_broadcast_body)

    e.expects(:fetch_mapping).returns(EmailMapping.new(user: User.new))
    e.rebuild_broadcast
  end

  test 'rebuild_broadcast should create a broadcast' do
    Broadcast.unstub(:create_with_user)
    e = EmailMessage.new
    e.stubs(:fetch_mapping).returns(EmailMapping.new(user: @user, entity: @line_item))
    e.expects(:email_to_broadcast_body).returns('body')
    assert_difference('Broadcast.count') { e.rebuild_broadcast }

    broadcast = Broadcast.last

    assert_equal 'Zen Spa: body', broadcast.full_body
    assert_equal @user, broadcast.author
    assert_equal @line_item, broadcast.line_item
  end

  test 'rebuild_broadcast should add the from address as a contact point of the user of the mapping' do
    u = User.new
    e = EmailMessage.new
    e.stubs(:email_to_broadcast_body)
    e.stubs(:fetch_mapping).returns(EmailMapping.new(user: u))
    e.expects(:add_from_as_contact_of).with(u)
    e.rebuild_broadcast
  end

  test 'to_backend? should return true if its uid is present' do
    e = EmailMessage.new(uid: 'something')
    assert e.to_backend?
  end

  test 'to_backend? should return false if its uid is nil' do
    e = EmailMessage.new(uid: nil)
    assert !e.to_backend?
  end

  test 'contact_point should fetch the contact point whose address is the email to address' do
    cp = ContactPoint::Email.new(description: 'address@address.com')
    cp.save(validate: false)

    assert_equal cp, EmailMessage.new(to: 'address@address.com').contact_point
  end

  test 'contact_point should return nil if there is no contact point whose address is the email to address' do
    cp = ContactPoint::Email.new(description: 'address2@address.com')
    cp.save(validate: false)

    assert_nil EmailMessage.new(to: 'address@address.com').contact_point
  end

  test 'to_user should return the user of the contact point' do
    e = EmailMessage.new
    e.stubs(:contact_point).returns(ContactPoint::Email.new(user: @user))
    assert_equal @user, e.to_user
  end

  test 'email_to_broadcast_body should replace any group of whitespace with space' do
    e = EmailMessage.new(body: "\n\nword\t   another word \r\n\r and a last word   ")
    assert_equal ' word another word and a last word ', e.send(:email_to_broadcast_body)
  end

  test 'email_to_broadcast_body should truncate the body to the length specified by MAX_EMAIL_REPLY_LENGTH' do
    e = EmailMessage.new(body: token_of_length(EmailMessage::MAX_EMAIL_REPLY_LENGTH + 5000))
    assert_equal EmailMessage::MAX_EMAIL_REPLY_LENGTH, e.send(:email_to_broadcast_body).length
  end

  test 'fetch_mapping should get a mapping for the mail' do
    mapping = EmailMapping.create_for(@user, @line_item)
    @line_item.organization_resource.update!(organization: Organization.create!(name: 'org', uniqueid: 'org'))
    e = EmailMessage.new(from: 'email@email.com', to: mapping.email_address('domain.com'))

    assert_equal mapping, e.send(:fetch_mapping)
  end

  test 'fetch_mapping should raise a NoRouteFoundException if there is no email mapping whose code matchs the to address tail' do
    mapping = EmailMapping.create_for(@user, @line_item)
    @line_item.organization_resource.update!(organization: Organization.create!(name: 'org', uniqueid: 'org'))
    e = EmailMessage.new(from: 'email@email.com', to: mapping.email_address('domain.com').sub(/.@/, 'imposiblelength@'))
    assert_raises(NoRouteFoundException) do
      e.send(:fetch_mapping)
    end
  end

  test 'reply_code should return the code after the + in the to address' do
    Organization.create!(name: 'org', uniqueid: 'orguid')
    e = EmailMessage.new(to: 'orguid+123456@email.com')
    assert_equal '123456', e.send(:reply_code)
  end

  test 'new_inbound should return a new record with its attributes filled with the args passed' do
    EmailMessage.stubs(:backend_address).returns('orgid+123456@mail.com')
    EmailMessage.stubs(:body_without_quotes).returns('some body to love')

    new_record = EmailMessage.new_inbound(MessageID: 'uid123', FromFull: { Email: 'from@mail.com' }, Subject: 'some subject')
    assert new_record.new_record?
    assert_equal 'uid123', new_record.uid
    assert_equal 'orgid+123456@mail.com', new_record.to
    assert_equal 'from@mail.com', new_record.from
    assert_equal 'some subject', new_record.subject
    assert_equal 'some body to love', new_record.body
  end

  test 'create_inbound should create an EmailMessage' do
    args = { some: 'args' }
    e = EmailMessage.new(from: 'from@from.com', to: 'to@to.com', body: 'body', subject: 'subject', uid: 'uid')

    e.expects(:rebuild_broadcast)
    EmailMessage.expects(:new_inbound).with(args).returns(e)
    assert_difference('EmailMessage.count') { EmailMessage.create_inbound(args) }
  end

  test 'create_inbound shouldnt do anything if the inbound email has already been processed' do
    e = EmailMessage.new(uid: 'existing_uid')
    e.save(validate: false)

    EmailMessage.expects(:new_inbound).never
    assert_no_difference('EmailMessage.count') { EmailMessage.create_inbound(MessageID: 'existing_uid') }
  end

  test 'backend_address should find the to address related to our app' do
    domain_address = "this_address@#{ ENV['MAIL_DOMAIN'] }"
    assert_equal domain_address, EmailMessage.backend_address([ { Email: 'another_address@mail.com'}, { Email: 'another_other_address@mail2.com'}, { Email: domain_address}])
  end

  test 'body_without_quotes should rely on EmailReplyParser' do
    EmailReplyParser.expects(:parse_reply).with('body').returns('body')
    EmailMessage.body_without_quotes('body')
  end

  test 'body_without_quotes should remove leading and trailing whitespace' do
    assert_equal 'body', EmailMessage.body_without_quotes("\n\t   body   \r\n")
  end

  test 'body_without_quotes should remove the gmail multiline quotes' do
    body = <<-BODY
body some words

2014-03-06 20:33 GMT-03:00 lets arrange (backend) <
info+gbvqpf-a6daxrnc7mpqryjxpryu_etnc@mail.backend.letsarrange.com>:
    BODY
    assert_equal 'body some words', EmailMessage.body_without_quotes(body)
  end

  test 'body_without_quotes should remove Sent via' do
    body = <<-BODY
body some words

Sent via something
More words
    BODY
    assert_equal 'body some words', EmailMessage.body_without_quotes(body)
  end

  test 'body_without_quotes should remove the outlook web access quotes' do
    body = <<-BODY
body some words

_____________________
More words
    BODY
    assert_equal 'body some words', EmailMessage.body_without_quotes(body)
  end

  test 'add_from_as_contact_of should create an email contact point with the form address and the user given' do
    u = create_user
    e = EmailMessage.new(from: 'new_mail@mail.com')
    assert_difference 'u.contacts_email.count' do
      e.send(:add_from_as_contact_of, u)
      created_cp = u.contacts_email.last
      assert_equal 'new_mail@mail.com', created_cp.email
    end
  end
end