module ContactPoint::Phone
  extend ActiveSupport::Concern

  included do
    validate :unique_number_cross_type, on: :create
    validate :number_format
    before_validation :normalize
    after_save :trust_related_contact, if: :just_verified?

    alias_attribute :number, :description
  end

  def normalized_number
    ContactPoint::Phone.normalize(number)
  end

  def denormalized
    ContactPoint::Phone.denormalized(description)
  end
  alias_method :to_s, :denormalized

  private

  def unique_number_cross_type
    errors.add(:number, 'phone is already in use') if user.contact_points.where(type: type, description: number).exists? || ContactPoint.unscoped.without_deleted.phone.where(description: number).where.not(user: user).exists?
  end

  def normalize
    self.number = normalized_number
  end

  def number_format
    errors.add(:base, 'Please provide a valid number') unless Phony.plausible?(number)
    errors.add(:base, 'Please provide a shorter number') unless number.length <= 15
  end

  def trust_related_contact
    related_cp = user.contacts_phone.unverified.where.not(id: id).find_by(description: description)
    related_cp.trust if related_cp
  end

  def just_verified?
    verified? && (status_was == ContactPointState::UNVERIFIED || status_was == ContactPointState::TRUSTED)
  end

  class << self
    def normalize(number)
      Phony.normalize(number, cc: '1')
    end

    def denormalized(number)
      cc, ndc, local = Phony.formatted(number, format: :national).split
      "(#{ cc }) #{ ndc }-#{ local }"
    end

    def area_code(number)
      Phony.formatted(number, format: :national).split.first
    end
  end
end