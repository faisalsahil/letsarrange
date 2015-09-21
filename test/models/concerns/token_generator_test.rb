require 'test_helper'

class TokenGeneratorTest < ActiveSupport::TestCase
  def setup
    super
    @includer = Hash.new #use Hash to make use of native support of [:key]
    Hash.send(:include, TokenGenerator)
  end

  test 'it should respond to generate_token' do
    assert_respond_to @includer, :generate_token
  end

  test 'it should generate a token of length n' do
    Hash.stubs(:exists?).returns(false)
    @includer.generate_token(:name, length: 10)
    assert_equal 10, @includer[:name].length
  end

  test 'it should generate a new code until it is unique' do
    Hash.stubs(:exists?).returns(true, false)
    SecureRandom.expects(:urlsafe_base64).twice
    @includer.generate_token(:name)
  end

  test 'it should generate a url safe token' do
    Hash.stubs(:exists?).returns(false)
    @includer.generate_token(:name, length: 10_000)
    assert_equal URI.escape(@includer[:name]), @includer[:name]
  end

  test 'it should be case sensitive by default' do
    SecureRandom.stubs(:urlsafe_base64).returns('nOtRaNdOm')
    Hash.expects(:exists?).with(name: 'nOtRaNdOm').returns(false)
    @includer.generate_token(:name)
    assert_equal 'nOtRaNdOm', @includer[:name]
  end

  test 'it should downcase the code generated if passed case_sensitive: false' do
    SecureRandom.stubs(:urlsafe_base64).returns('nOtRaNdOm')
    Hash.expects(:exists?).with(name: 'notrandom').returns(false)
    @includer.generate_token(:name, case_sensitive: false)
    assert_equal 'notrandom', @includer[:name]
  end
end