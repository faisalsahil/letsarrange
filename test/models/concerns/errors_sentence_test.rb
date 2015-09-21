require 'test_helper'

class ErrorsSentenceTest < ActiveSupport::TestCase
  test 'errors_sentence should join the errors and fields' do
    request = Request.new
    request.errors.add(:ideal_start, 'some error message')
    request.errors.add(:finish_by, 'another error message')
    assert_equal 'some error message and another error message', request.errors_sentence
  end
end


