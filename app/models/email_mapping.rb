class EmailMapping < Mapping
  include TokenGenerator

  def email_address(domain)
    "#{ entity.mail_prefix(user) }+#{ code }@#{ domain }"
  end

  private

  def generate_code
    generate_token(:code, case_sensitive: false)
  end

  def self.create_for(user, entity)
    user.email_mappings.active.for_entity(entity).first_or_create!
  end
end