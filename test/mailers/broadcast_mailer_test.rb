require 'test_helper'

class BroadcastMailerTest < ActionMailer::TestCase
  test 'new_broadcast should send a mail with the email given by id' do
    email = EmailMessage.create(to: 'to@to.com', from: 'from@from.com', body: 'body', subject: 'subject')
    BroadcastMailer.any_instance.expects(:mail).with(to: 'to@to.com', from: 'from@from.com', body: 'body', subject: 'subject')
    BroadcastMailer.send(:new).new_broadcast(email.id)
  end

  test 'error_message should send a mail with the message given as body' do
    BroadcastMailer.any_instance.expects(:mail).with(to: 'to@to.com', from: 'from@from.com', body: 'exception message', subject: 'An error occurred')
    BroadcastMailer.send(:new).error_message('from@from.com', 'to@to.com', 'exception message')
  end
end
