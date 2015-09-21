require 'test_helper'

class ContactPoint::PhoneTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Sms.new(user: @user)
  end

  test 'it should have number as alias of description' do
    assert_equal 'description', ContactPoint::Sms.attribute_aliases['number']
  end

  test 'it should verify voice and sms numbers' do
    @contact_point.description = "+1 555-555-5555"
    assert @contact_point.valid?
  end

  test 'it should not allow invalid voice and sms numbers' do
    @contact_point.description = "300"
    assert !@contact_point.valid?
    assert @contact_point.errors.messages[:base].include? "Please provide a valid number"
  end

  test 'it should not allow numbers greater than 15 digits' do
    @contact_point.description = "+1 555-555-555599999"
    assert !@contact_point.valid?
    assert @contact_point.errors.messages[:base].include? "Please provide a shorter number"
  end

  test 'it should normalize voice and sms numbers before validations' do
    @contact_point.description = "+1 555-555-5555"
    assert @contact_point.valid?
    assert_equal "15555555555",@contact_point.description
  end

  test 'denormalized should show the number in a friendly way' do
    @contact_point.number = '12349876543'
    assert_equal '(234) 987-6543', @contact_point.denormalized
  end

  test 'normalized_number should return a db storable phone number' do
    assert_equal '12345678901', ContactPoint::Sms.new(number: '(234) 567-8901').normalized_number
  end

  test 'it should validate uniqueness of phone(sms or voice) between different users' do
    cp = ContactPoint::Voice.new(description: '13454567890', user_id: 9999)
    cp.save(validate: false)

    @contact_point.description = '(345) 456-7890'
    assert @contact_point.invalid?
  end

  test 'it should not validate uniqueness for sms and voice for same user' do
    cp = ContactPoint::Voice.new(description: '13454567890', user: @user)
    cp.save(validate: false)

    @contact_point.description = '(345) 456-7890'
    assert @contact_point.valid?
  end

  test 'it should call trust_related_contact after save' do
    cp = ContactPoint::Voice.new(description: '13454567890', user: @user)
    cp.expects(:just_verified?).returns(true)
    cp.expects(:trust_related_contact)
    cp.save(validate: false)
  end

  test 'it should not call trust_related_contact after save if it was not just_verified?' do
    cp = ContactPoint::Voice.new(description: '13454567890', user: @user)
    cp.expects(:just_verified?).returns(false)
    cp.expects(:trust_related_contact).never
    cp.save(validate: false)
  end

  test 'trust_related_contact should set to trusted the status of the contact that shares user and number' do
    cp2 = ContactPoint::Sms.new(description: '13454567890', user: @user)
    cp2.save(validate: false)
    user2 = create_user(name: 'userName2', uniqueid: 'uniqueid2')
    cp3 = ContactPoint::Sms.new(description: '13454567890', user: user2)
    cp3.save(validate: false)
    cp4 = ContactPoint::Sms.new(description: '13454567891', user: @user)
    cp4.save(validate: false)

    cp = ContactPoint::Voice.new(description: '13454567890', user: @user)
    cp.stubs(:just_verified?).returns(true)

    assert cp2.unverified?
    cp.save(validate: false)
    assert cp2.reload.trusted?
  end

  test 'just_verified? should return true if it is verified and the previous status was unverified' do
    @contact_point.stubs(:status).returns(ContactPointState::VERIFIED)
    @contact_point.stubs(:status_was).returns(ContactPointState::UNVERIFIED)
    assert @contact_point.send(:just_verified?)
  end

  test 'just_verified? should return true if it is verified and the previous status was trusted' do
    @contact_point.stubs(:status).returns(ContactPointState::VERIFIED)
    @contact_point.stubs(:status_was).returns(ContactPointState::TRUSTED)
    assert @contact_point.send(:just_verified?)
  end

  test 'just_verified? should return false if it is not verified' do
    @contact_point.stubs(:status).returns(ContactPointState::UNVERIFIED)
    assert !@contact_point.send(:just_verified?)
  end

  test 'just_verified? should return false if the previous status was not unverified nor trusted' do
    @contact_point.stubs(:status).returns(ContactPointState::VERIFIED)
    @contact_point.stubs(:status_was).returns(ContactPointState::DISABLED)
    assert !@contact_point.send(:just_verified?)
  end

  test 'area_code should return the area code of a phone number' do
    assert_equal '345', ContactPoint::Phone.area_code('13451111111')
  end
end