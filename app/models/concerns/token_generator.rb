module TokenGenerator
  def generate_token(field, length: 32, case_sensitive: true)
    length = length * 3 / 4
    begin
      token = SecureRandom.urlsafe_base64(length)
      self[field] = case_sensitive ? token : token.downcase
    end while self.class.exists?(field => self[field])
  end
end