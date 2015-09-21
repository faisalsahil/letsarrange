module ErrorsSentence
  def errors_sentence
    errors.messages.values.flatten.to_sentence
  end
end