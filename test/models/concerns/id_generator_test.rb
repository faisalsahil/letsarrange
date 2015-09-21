require 'test_helper'

class IdGeneratorWrapper 
	include IdGenerator
end

class IdGeneratorTest < ActiveSupport::TestCase
	test "it responds to make_unique" do 
		assert_respond_to IdGeneratorWrapper, :make_unique
	end

	test "clean should allow - " do 
		assert_equal "resource-name-2014", IdGeneratorWrapper.clean("resource-name-2014!")
	end

	test "make unique should ensure that an id its unique for a given model" do
		assert_equal "uniqueid1", IdGeneratorWrapper.make_unique("uniqueid1",User)
	end

	test "make unique should resolve naming collisions" do
		create_user(uniqueid: 'uniqueid1')

		assert_equal 'uniqueid2', IdGeneratorWrapper.make_unique('uniqueid1', User)
	end
end