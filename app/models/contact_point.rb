class ContactPoint < ActiveRecord::Base
  include ErrorsSentence

  belongs_to :user, inverse_of: :contact_points
  has_many :url_mappings, dependent: :destroy
  has_many :requests, inverse_of: :contact_point

  before_create :set_default_notifications

  validates_presence_of :description, :user

  scope :enabled, -> { where(status: [ContactPointState::UNVERIFIED, ContactPointState::VERIFIED, ContactPointState::TRUSTED]) }
  scope :verified, -> { where(status: ContactPointState::VERIFIED) }
  scope :unverified, -> { where(status: ContactPointState::UNVERIFIED) }
  scope :trusted_or_verified, -> { where(status: [ContactPointState::TRUSTED, ContactPointState::VERIFIED]) }
  scope :notifiable, -> { where(status: ContactPointState::VERIFIED, notifications_enabled: true) }
  scope :verifiable, -> { where(status: [ContactPointState::UNVERIFIED, ContactPointState::TRUSTED]) }
  scope :phone, -> { where(type: ['ContactPoint::Sms', 'ContactPoint::Voice']) }
  %i(sms voice email).each do |type|
    scope type, -> { where(type: full_type(type)) }  #scope :sms, -> { where(type: 'ContactPoint::Sms') }
  end

  add_status_with ContactPointState, soft_delete: true

  def humanized_status(opts = {})
    return 'notifications enabled' if notifiable?
    status = trusted? && !opts[:for_admin] ? ContactPointState::UNVERIFIED : self.status
    ContactPointState::HUMANIZED[status]
  end

  def mark_as_verified!
    if unverified? || trusted?
      self.confirmed_at = Time.now.utc
      self.confirmation_token = nil
      change_status(:verified)
      save
    end
  end

  def phone?
    sms? || voice?
  end

  def sms?
    is_a?(ContactPoint::Sms)
  end

  def voice?
    is_a?(ContactPoint::Voice)
  end

  def email?
    is_a?(ContactPoint::Email)
  end

  def unverified?
    status == ContactPointState::UNVERIFIED
  end

  def verified?
    status == ContactPointState::VERIFIED
  end

  def trusted?
    status == ContactPointState::TRUSTED
  end

  def disabled?
    status == ContactPointState::DISABLED
  end

  def enabled?
    !disabled?
  end

  def notifiable?
    verified? && notifications_enabled
  end

  def disable
    change_status(:disabled)
  end

  def enable
    disable_notifications
    change_status(:verified)
  end

  def enable_notifications
    update(notifications_enabled: true)
  end

  def disable_notifications
    update(notifications_enabled: false)
  end

  def trust
    change_status(:trusted)
  end

  def notification_captions(action)
    { disable: 'disable notifications', enable: 'enable notifications' }[action]
  end

  private

  def notifiable_was?
    status_was == ContactPointState::VERIFIED && notifications_enabled_was
  end

  def set_default_notifications
    self.notifications_enabled = true if notifications_enabled.nil?
    true
  end

  def self.from_hash(hash)
    cp = hash.slice(:sms, :voice, :email).reject { |_, d| d.blank? }

    [:sms, :voice].each do |contact|
      cp[contact] = Phony.normalize(cp[contact], cc: '1')  if cp[contact].present?
    end

    cp
  end

  def self.create_sms_and_phone(user, number)
    #by design: let one be created even if the other fails
    cp1 = user.contact_points.create(type: 'ContactPoint::Sms', description: number)
    cp2 = user.contact_points.create(type: 'ContactPoint::Voice', description: number)
    { created: [cp1, cp2].select(&:persisted?), failed: [cp1, cp2].reject(&:persisted?) }
  end

  def self.create_with_type(*args)
    attrs = args.first
    attrs[:type] ||= full_type(attrs.delete(:contact_type))
    create(*args)
  end

  def self.full_type(short_type)
    case short_type.to_s
    when 'sms' then 'ContactPoint::Sms'
    when 'voice' then 'ContactPoint::Voice'
    when 'email' then 'ContactPoint::Email'
    else
      fail
    end
  end

  def self.find_phone(raw_description)
    where(description: ContactPoint::Phone.normalize(raw_description)).order('type DESC').first
  end
end