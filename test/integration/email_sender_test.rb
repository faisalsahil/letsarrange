require 'test_helper'

class EmailSenderTest < ActiveSupport::TestCase
  def setup
    super
    line_item_with_assoc!
    @contact_point = ContactPoint::Email.create!(user: @user, description: 'email@email.com')
    @user.create_mappings(@line_item, true)

    User.stubs(:find_user).returns([@user])
    Broadcast.any_instance.stubs(:send_messages)
    EmailMapping.any_instance.stubs(:email_address).returns('some@address.com')

    @broadcast = @line_item.create_opening_broadcast(@user)
    @broadcast.assign_attributes(body: 'body of the broadcast', created_at: Time.now)
  end

  test 'send_message should add a new row to the delayed_jobs table' do
    assert_difference "Delayed::Job.count" do
      EmailSender.send_message(@broadcast, @contact_point)
    end
  end

  test 'send_message should create a UrlMapping' do
    UrlMapping.expects(:create_for).with(@contact_point, @line_item).returns(UrlMapping.new(code: 'somecode'))
    EmailSender.send_message(@broadcast, @contact_point)
  end

  test 'send_message should fetch an EmailMapping' do
    EmailMapping.expects(:mapping_for).with(@contact_point.user, @line_item).returns(EmailMapping.new(code: '123'))
    EmailSender.send_message(@broadcast, @contact_point)
  end

  test 'send_message should create an EmailMessage' do
    EmailSender.expects(:mail_body).returns('some body to love')
    EmailSender.expects(:mail_from).returns('from address')
    EmailSender.expects(:subject).with('Zen Spa').returns('the subject')
    assert_difference 'EmailMessage.count' do
      EmailSender.send_message(@broadcast, @contact_point)
      created = EmailMessage.last
      assert_equal 'some body to love', created.body
      assert_equal 'from address', created.from
      assert_equal @contact_point.email, created.to
      assert_equal 'the subject', created.subject
    end
  end

  test 'subject should return Message from followed by the sender given' do
    assert_equal "Message from a sender", EmailSender.send(:subject, 'a sender')
  end

  test 'mail_body should start with New message' do
    mapping = UrlMapping.new(path: 'some_path', code: 'somecode')

    assert_not_nil EmailSender.send(:mail_body, @broadcast, mapping)["New message via letsarrange.com"]
  end

  test 'mail_body should have the formatted creation date of the broadcast' do
    created_at = Time.new(2014, 1, 2, 3, 4, 5, '-03:00')
    @broadcast.assign_attributes(created_at: created_at)
    mapping = UrlMapping.new(path: 'some_path', code: 'somecode')

    assert_not_nil EmailSender.send(:mail_body, @broadcast, mapping)['1/2 6:04am']
  end

  test 'mail_body should have the body of the broadcast' do
    mapping = UrlMapping.new(path: 'some_path', code: 'somecode')

    assert_not_nil EmailSender.send(:mail_body, @broadcast, mapping)['body of the broadcast']
  end

  test 'mail_body should not have the author_name of the broadcast' do
    @broadcast.stubs(:author_name).returns('author name')
    mapping = UrlMapping.new(path: 'some_path', code: 'somecode')

    assert_nil EmailSender.send(:mail_body, @broadcast, mapping)['author name']
  end

  test 'mail_body should have a footer message' do
    mapping = UrlMapping.new(path: 'some_path', code: 'somecode')
    mapping.stubs(:to_url).returns('some.url/code')

    assert_not_nil EmailSender.send(:mail_body, @broadcast, mapping)['Go to some.url/code, or reply by email.']
  end

  test 'send_exception_message should add a new row to the delayed_jobs table' do
    assert_difference "Delayed::Job.count" do
      EmailSender.send_exception_message(NoRouteFoundException.new, 'from@from.com', 'to@to.com')
    end
  end

  test 'send_exception_message should call error_message on BroadcastMailer' do
    e = NoRouteFoundException.new

    BroadcastMailer.stubs(:delay).returns(BroadcastMailer)
    BroadcastMailer.expects(:error_message).with('from@from.com', 'to@to.com', e.to_mail)
    EmailSender.send_exception_message(NoRouteFoundException.new, 'from@from.com', 'to@to.com')
  end

  test 'send_password_reset should add a new row to the delayed_jobs table' do
    assert_difference "Delayed::Job.count" do
      EmailSender.send_password_reset(@contact_point, 'some token')
    end
  end

  test 'send_password_reset should call password_reset on PasswordMailer' do
    PasswordMailer.stubs(:delay).returns(PasswordMailer)
    PasswordMailer.expects(:password_reset).with(@contact_point.id, 'token')
    EmailSender.send_password_reset(@contact_point, 'token')
  end

  test 'mail_from should return author_name <prefix+code@mail_domain> for the broadcast and mapping given' do
    EmailSender.expects(:mail_domain).returns('domain.com')
    b = Broadcast.new
    b.stubs(:author_name).returns('author at organization')
    mapping = EmailMapping.new(code: '123code')
    mapping.expects(:email_address).with('domain.com').returns('prefix+123code@domain.com')

    assert_equal "author at organization <prefix+123code@domain.com>", EmailSender.send(:mail_from, b, mapping)
  end

  test 'mail_domain should return the humanized domain if the broadcast is using humanized_sender?' do
    b = Broadcast.new
    b.expects(:humanized_sender?).returns(true)
    assert_equal EmailMessage::MAIL_DOMAINS[:humanized], EmailSender.send(:mail_domain, b)
  end

  test 'mail_domain should return the systemized domain if the broadcast is not using humanized_sender?' do
    b = Broadcast.new
    b.expects(:humanized_sender?).returns(false)
    assert_equal EmailMessage::MAIL_DOMAINS[:systemized], EmailSender.send(:mail_domain, b)
  end
end