class ContactPoint::Email < ContactPoint
  prepend EmailVerifiable

  validate :email_format
  validate :unique_address, on: :create

  alias_attribute :email, :description

  def to_s
    email
  end

  def email?
    super
  end

  def humanized_type
    'Email'
  end

  def short_type
    'email'
  end

  def emails_sent_and_received
    EmailMessage.with_address(email)
  end

  def send_password_reset(token)
    EmailSender.send_password_reset(self, token)
  end

  private

  def email_format
    errors.add(:base, 'Please provide a valid email') unless description =~ (/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
  end

  def unique_address
    errors.add(:email, 'email is already in use') if ContactPoint::Email.where(description: email).exists?
  end

  def self._to_partial_path
    'contact_points/email'
  end
end