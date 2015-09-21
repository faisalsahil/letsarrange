require 'test_helper'

class ContactPoint::VoiceTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Voice.new(user: @user, description: '13459876543')
  end

  should have_one :user_to_reset

  test 'can_clone_to_sms? should check if an sms with the same number exists' do
    cp = ContactPoint::Sms.new(number: '13454567890')
    cp.save(validate: false)
    @contact_point.number = '(345) 456-7890'
    assert !@contact_point.can_clone_to_sms?

    @contact_point.number = '(345) 456-7891'
    assert @contact_point.can_clone_to_sms?
  end

  test 'it sould include VoiceVerifiable' do
    assert_includes ContactPoint::Voice.ancestors, VoiceVerifiable
  end

  test 'it should validate uniqueness of voice' do
    cp = ContactPoint::Voice.new(description: '13454567890', user_id: 9999)
    cp.save(validate: false)

    @contact_point.description = '(345) 456-7890'
    assert @contact_point.invalid?
  end

  test 'find_phone should normalize the number before querying' do
    @contact_point.number = '(345) 123-4567'
    @contact_point.save
    assert_equal @contact_point, ContactPoint::Voice.find_phone('(345) 123-4567')
  end

  test 'send_password_reset should setup the user for password reset via voice' do
    @user.expects(:setup_for_reset_via_voice).with(@contact_point)
    assert_equal '123456', @contact_point.send_password_reset('123456')
  end

  test 'able_to_reset? should return true if its state is verified and the user_to_reset has voice_reset_active' do
    @user.stubs(:voice_reset_active?).returns(true)
    @contact_point.stubs(:user_to_reset).returns(@user)
    @contact_point.status = ContactPointState::VERIFIED
    @contact_point.save!
    assert @contact_point.able_to_reset?
  end

  test 'able_to_reset? should return false if its state is not verified' do
    @user.stubs(:voice_reset_active?).returns(true)
    @contact_point.stubs(:user_to_reset).returns(@user)
    @contact_point.status = ContactPointState::UNVERIFIED
    @contact_point.save(validate: false)
    assert !@contact_point.able_to_reset?
  end

  test 'able_to_reset? should return false if the user_to_reset does not have voice_reset_active' do
    @user.stubs(:voice_reset_active?).returns(false)
    @contact_point.stubs(:user_to_reset).returns(@user)
    @contact_point.status = ContactPointState::VERIFIED
    @contact_point.save(validate: false)
    assert !@contact_point.able_to_reset?
  end

  test 'enable_notifications should disable the notifications of the current preferred voice contact of its user' do
    previous = ContactPoint::Voice.create!(user: @user, description: '13454444444', status: ContactPointState::VERIFIED)
    @contact_point.update!(status: ContactPointState::VERIFIED, description: '13455555555')
    assert_equal previous, @user.preferred_voice
    @contact_point.enable_notifications
    assert_equal @contact_point, @user.preferred_voice
    assert !previous.reload.notifications_enabled?
  end

  test 'it should call check_preferred after save if it is not notifiable?' do
    @contact_point.expects(:notifiable?).returns(false)
    @contact_point.expects(:check_preferred)
    @contact_point.save(validate: false)
  end

  test 'it should not call check_preferred after save if it is notifiable?' do
    @contact_point.expects(:notifiable?).returns(true)
    @contact_point.expects(:check_preferred).never
    @contact_point.save(validate: false)
  end

  test 'check_preferred should call ensure_preferred_voice on user if it was notifiable?' do
    @contact_point.expects(:notifiable_was?).returns(true)
    @contact_point.expects(:id).returns('5')
    @user.expects(:ensure_preferred_voice).with('5')
    @contact_point.send(:check_preferred)
  end

  test 'check_preferred should call enable_notifications if it was not notifiable? and it is verified? and the user has no preferred_voice' do
    @contact_point.expects(:notifiable_was?).returns(false)
    @contact_point.expects(:verified?).returns(true)
    @user.expects(:preferred_voice).returns(nil)
    @contact_point.expects(:enable_notifications)
    @contact_point.send(:check_preferred)
  end

  test 'set_default_notifications should set notifications_enabled to false if not present' do
    cp = ContactPoint::Voice.new
    assert_nil cp.notifications_enabled
    cp.send(:set_default_notifications)
    assert !cp.notifications_enabled
  end

  test 'notification_captions should return remove as active if the action given is disable' do
    assert_equal 'remove as active', ContactPoint::Voice.new.notification_captions(:disable)
  end

  test 'notification_captions should return set as active if the action given is enable' do
    assert_equal 'set as active', ContactPoint::Voice.new.notification_captions(:enable)
  end

  test 'humanized_status should return active if it is notifiable' do
    @contact_point.stubs(:notifiable?).returns(false)
    assert_not_equal 'active', @contact_point.humanized_status
    @contact_point.stubs(:notifiable?).returns(true)
    assert_equal 'active', @contact_point.humanized_status
  end
end