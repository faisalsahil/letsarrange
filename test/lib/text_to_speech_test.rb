require 'test_helper'

class TextToSpeechTest < ActiveSupport::TestCase
  test 'convert should return the text given unchanged if it has no numbers' do
    assert_equal 'something without numbers', TextToSpeech.convert('something without numbers')
  end

  test 'convert should remove extra whitespaces' do
    assert_equal 'us er name', TextToSpeech.convert('us    er   name   ')
  end

  test 'convert should wrap each digit in the text with spaces' do
    assert_equal '1 2 3 pablo 4 5 6 t 7 e 8 s 9 t 0', TextToSpeech.convert('123 pablo456 t7e8s9t0')
  end

  test 'convert should remove special chars' do
    assert_equal 'some body to love', TextToSpeech.convert('--)_(some-body (to) __)love-)')
  end
end