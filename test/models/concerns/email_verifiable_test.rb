require 'test_helper'

class EmailVerifiableTest < ActiveSupport::TestCase
  def setup
    super
    @contact_point = ContactPoint::Email.new
  end

  test 'confirmed? should call verified?' do
    @contact_point.expects(:verified?)
    @contact_point.confirmed?
  end

  test 'after_confirmation should change the status to verified' do
    @contact_point.after_confirmation
    assert_equal ContactPointState::VERIFIED, @contact_point.status
  end

  test 'it should send a verification email on create if it is created unverified' do
    @contact_point.status = ContactPointState::UNVERIFIED
    @contact_point.save(validate: false)
    assert_not_nil @contact_point.confirmation_token
    assert_not_nil @contact_point.confirmation_sent_at
  end

  test 'it should not send a verification email on create if it is created trusted' do
    @contact_point.status = ContactPointState::TRUSTED
    @contact_point.expects(:skip_confirmation_notification!)
    @contact_point.save(validate: false)
  end
end