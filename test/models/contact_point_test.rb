require 'test_helper'

class ContactPointTest < ActiveSupport::TestCase
	def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Sms.new(user: @user, description: '13451234567')
	end

	should belong_to :user
  should have_many :url_mappings
	should have_many :requests

	should validate_presence_of :description
	should validate_presence_of :user

  test 'create_sms_and_phone should create two contact points' do
    assert_difference 'ContactPoint.count', 2 do
      ContactPoint.create_sms_and_phone(@user, '(345) 123-4567')
    end
  end

  test 'create_sms_and_phone should create a contact point if the other fails' do
    @contact_point.description = '13451234567'
    @contact_point.save(validate: false)
    assert_difference 'ContactPoint.count' do
      ContactPoint.create_sms_and_phone(@user, '(345) 123-4567')
    end
  end

  test 'should have scopes per type' do
    assert ContactPoint.respond_to?(:sms)
    assert ContactPoint.respond_to?(:voice)
    assert ContactPoint.respond_to?(:email)
    assert ContactPoint.respond_to?(:phone)
  end

  test 'should have predicates to test the contact_type' do
    assert ContactPoint::Sms.new.sms?
    assert ContactPoint::Voice.new.voice?
    assert ContactPoint::Email.new.email?
    assert ContactPoint::Sms.new.phone?
  end

  test 'it should be created unverified' do
    @contact_point.save(validate: false)
    assert !@contact_point.verified?
  end

  test 'verified? should return true if the status is verified' do
    @contact_point.status = ContactPointState::VERIFIED
    assert @contact_point.verified?
  end

  test 'verified? should return false if the status is not verified' do
    @contact_point.status = ContactPointState::DISABLED
    assert !@contact_point.verified?
  end

  test 'disabled? should return true if the status is disabled' do
    @contact_point.status = ContactPointState::DISABLED
    assert @contact_point.disabled?
  end

  test 'disabled? should return false if the status is not disabled' do
    @contact_point.status = ContactPointState::VERIFIED
    assert !@contact_point.disabled?
  end

  test 'enabled? should return false if the status is disabled' do
    @contact_point.status = ContactPointState::DISABLED
    assert !@contact_point.enabled?
  end

  test 'enabled? should return true if the status is not disabled' do
    @contact_point.status = ContactPointState::VERIFIED
    assert @contact_point.enabled?
  end

  test 'disable should change the status to disabled' do
    @contact_point.status = ContactPointState::VERIFIED
    @contact_point.disable
    assert_equal ContactPointState::DISABLED, @contact_point.status
  end

  test 'enable should change the status to verified' do
    @contact_point.status = ContactPointState::DISABLED
    @contact_point.enable
    assert_equal ContactPointState::VERIFIED, @contact_point.status
  end

  test 'enable should disable the notifications' do
    @contact_point.expects(:disable_notifications)
    @contact_point.enable
  end

  test 'mark_as_verified! should set confirmed_at' do
    @contact_point.expects(:confirmed_at=)
    @contact_point.mark_as_verified!
  end

  test 'mark_as_verified! should clear confirmation_token' do
    @contact_point.confirmation_token = 'a token'
    @contact_point.mark_as_verified!
    assert_nil @contact_point.confirmation_token
  end

  test 'mark_as_verified! should change the status to verified' do
    @contact_point.status = ContactPointState::UNVERIFIED
    @contact_point.mark_as_verified!
    assert_equal ContactPointState::VERIFIED, @contact_point.status
  end

  test 'mark_as_verified! should do nothing if it is already verified' do
    @contact_point.status = ContactPointState::VERIFIED
    @contact_point.confirmation_token = 'a token'
    @contact_point.expects(:confirmed_at=).never
    @contact_point.mark_as_verified!
    assert_equal 'a token', @contact_point.confirmation_token
    assert_equal ContactPointState::VERIFIED, @contact_point.status
  end

  test 'enabled scope should include unverified and verified contact points' do
    @contact_point.status = ContactPointState::VERIFIED
    @contact_point.save(validate: false)
    cp2 = @contact_point.dup
    cp2.status = ContactPointState::UNVERIFIED
    cp2.save(validate: false)
    assert_equal 2, ContactPoint.enabled.count
  end

  test 'enabled scope should exclude disabled and deleted contact points' do
    @contact_point.status = ContactPointState::DISABLED
    @contact_point.save(validate: false)
    cp2 = @contact_point.dup
    cp2.status = ContactPointState::DELETED
    cp2.save(validate: false)
    assert_equal 0, ContactPoint.enabled.count
  end

  test 'verified scope should include verified contact points' do
    @contact_point.status = ContactPointState::VERIFIED
    @contact_point.save(validate: false)
    assert_equal [@contact_point], ContactPoint.verified.to_a
  end

  test 'verified scope should exclude unverified, disabled and deleted contact points' do
    @contact_point.status = ContactPointState::DISABLED
    @contact_point.save(validate: false)
    cp2 = @contact_point.dup
    cp2.status = ContactPointState::DELETED
    cp2.save(validate: false)
    cp2 = @contact_point.dup
    cp2.status = ContactPointState::UNVERIFIED
    cp2.save(validate: false)
    assert_equal [], ContactPoint.verified.to_a
  end

  test 'humanized_status should return unverified if the status is trusted and for admin is false or not present' do
    @contact_point.status = ContactPointState::TRUSTED
    assert_equal 'unverified', @contact_point.humanized_status
  end

  test 'humanized_status should return trusted if the status is trusted and for admin is true' do
    @contact_point.status = ContactPointState::TRUSTED
    assert_equal 'trusted', @contact_point.humanized_status(for_admin: true)
  end

  test 'humanized_status should return notifications enabled if it is notifiable' do
    @contact_point.expects(:notifiable?).returns(false)
    assert_not_equal 'notifications enabled', @contact_point.humanized_status
    @contact_point.expects(:notifiable?).returns(true)
    assert_equal 'notifications enabled', @contact_point.humanized_status
  end

  test 'unverified? should return true if the status is unverified' do
    @contact_point.status = ContactPointState::UNVERIFIED
    assert @contact_point.unverified?
  end

  test 'unverified? should return false if the status is not unverified' do
    @contact_point.status = ContactPointState::VERIFIED
    assert !@contact_point.unverified?
  end

  test 'trusted? should return true if the status is trusted' do
    @contact_point.status = ContactPointState::TRUSTED
    assert @contact_point.trusted?
  end

  test 'trusted? should return false if the status is not trusted' do
    @contact_point.status = ContactPointState::UNVERIFIED
    assert !@contact_point.trusted?
  end

  test 'create_with_type should create a contact point whose type is the value of type attribute' do
    cp = ContactPoint.create_with_type(type: 'ContactPoint::Email')
    assert cp.is_a?(ContactPoint::Email)
  end

  test 'create_with_type should create a contact point whose type is the full_type of contact_type attribute if type is not present' do
    ContactPoint.expects(:full_type).with('something').returns('ContactPoint::Email')
    cp = ContactPoint.create_with_type(contact_type: 'something')
    assert cp.is_a?(ContactPoint::Email)
  end

  test 'create_with_type should pass the extra parameters to create' do
    ContactPoint.expects(:create).with( { type: 'ContactPoint::Email' }, 'something', 'something 2')
    ContactPoint.create_with_type( { contact_type: 'email' }, 'something', 'something 2')
  end

  test 'full_type should return the stringified constant related to the short type passed' do
    assert_equal 'ContactPoint::Email', ContactPoint.full_type('email')
    assert_equal 'ContactPoint::Voice', ContactPoint.full_type('voice')
    assert_equal 'ContactPoint::Sms', ContactPoint.full_type('sms')
  end

  test 'full_type should raise a RuntimeError if an invalid short_type is passed' do
    assert_raise(RuntimeError) { ContactPoint.full_type('im not a type') }
  end

  test 'trust should change the status to trusted' do
    @contact_point.status = ContactPointState::UNVERIFIED
    @contact_point.trust
    assert_equal ContactPointState::TRUSTED, @contact_point.status
  end

  test 'notifiable scope should include records that are verified and enabled for notifications' do
    cp = ContactPoint::Sms.create!(user: @user, description: '13459876542', status: ContactPointState::VERIFIED, notifications_enabled: true)
    ContactPoint::Sms.create!(user: @user, description: '13459876541', status: ContactPointState::UNVERIFIED, notifications_enabled: true)
    ContactPoint::Sms.create!(user: @user, description: '13459876543', status: ContactPointState::VERIFIED, notifications_enabled: false)
    assert_equal [cp], ContactPoint.notifiable.to_a
  end

  test 'notifiable? should return true if it is verified? and notifications are enabled' do
    @contact_point.expects(:verified?).returns(true)
    @contact_point.expects(:notifications_enabled).returns(true)
    assert @contact_point.notifiable?
  end

  test 'notifiable? should return false if it is not verified?' do
    @contact_point.expects(:verified?).returns(false)
    @contact_point.stubs(:notifications_enabled).returns(true)
    assert !@contact_point.notifiable?
  end

  test 'notifiable? should return false if notifications are not enabled' do
    @contact_point.stubs(:verified?).returns(true)
    @contact_point.expects(:notifications_enabled).returns(false)
    assert !@contact_point.notifiable?
  end

  test 'enable_notifications should set notifications_enabled to true' do
    @contact_point.update!(notifications_enabled: false)
    assert !@contact_point.notifications_enabled
    @contact_point.enable_notifications
    assert @contact_point.notifications_enabled
  end

  test 'disable_notifications should set notifications_enabled to false' do
    @contact_point.update!(notifications_enabled: true)
    assert @contact_point.notifications_enabled
    @contact_point.disable_notifications
    assert !@contact_point.notifications_enabled
  end

  test 'set_default_notifications should be called before creation' do
    cp = ContactPoint::Voice.new(notifications_enabled: true)
    cp.expects(:set_default_notifications)
    cp.save!(validate: false)
  end

  test 'set_default_notifications should set notifications_enabled to false if not present' do
    cp = ContactPoint::Sms.new
    assert_nil cp.notifications_enabled
    cp.send(:set_default_notifications)
    assert cp.notifications_enabled
  end

  test 'notification_captions should return disable notifications if the action given is disable' do
    assert_equal 'disable notifications', ContactPoint.new.notification_captions(:disable)
  end

  test 'notification_captions should return enable notifications if the action given is enable' do
    assert_equal 'enable notifications', ContactPoint.new.notification_captions(:enable)
  end
end