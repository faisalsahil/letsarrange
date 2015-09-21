class Broadcast < ActiveRecord::Base
  SENDERS = {
    ContactPoint::Voice => VoiceBroadcastSender,
    ContactPoint::Email => EmailSender
  }

  belongs_to :organization_user
  has_one :user, through: :organization_user
  belongs_to :broadcastable, polymorphic: true
  alias_method :line_item, :broadcastable
  alias_method :inbound_number, :broadcastable

  with_options dependent: :destroy do |a|
    a.has_many :sms_messages
    a.has_many :email_messages
  end

  with_options presence: true do |v|
    v.validates :organization_user, unless: :for_request?
    v.validates :broadcastable
    v.validates :body
  end

  after_create :send_messages

  delegate :time_zone, :humanized_messages?, :systemized_messages?, to: :request
  delegate :to_humanized_sentence, to: :broadcastable
  with_options to: :broadcastable, allow_nil: true do |d|
    d.delegate :request, :requested_organization, :requesting_organization
    d.delegate :receiver, :author, prefix: true
  end

  scope :of_inbound_numbers, -> (inbound_numbers) { where(broadcastable_type: InboundNumber, broadcastable_id: inbound_numbers) }

  attrs_in_tmz :created_at

  def opening_broadcast?
    broadcastable.no_replies?
  end

  def to_requested?
    broadcastable.requesting_user?(user)
  end

  def author
    organization_user.try(:user) || fake_author
  end

  def author_name
    organization_user.try(:full_name) || fake_author.name
  end

  def fake_author
    User.find_user(sms: sender_number).first || User.new(name: ContactPoint::Phone.denormalized(sender_number))
  end

  def author_rep
    " #{request.contact_point}" if request.contact_point
  end

  def full_body
    "#{ author_name }: #{ body }"
  end

  def humanized_sender?
    to_requested? && humanized_messages?
  end

  private

  def sender_number
    inbound_number.number
  end

  def send_messages
    target_contacts.each do |cp|
      sender_for_contact(cp).send_message(self, cp)
    end
  end

  def for_request?
    broadcastable.is_a?(InboundNumber)
  end

  def sender_for_contact(contact_point)
    if contact_point.is_a?(ContactPoint::Sms)
      humanized_sender? ? HumanizedSmsSender : SystemizedSmsSender
    else
      SENDERS[contact_point.class]
    end
  end

  def target_contacts
    contacts = to_requested? ? broadcastable.receiver_contacts : broadcastable.author_contacts
    contacts.any?(&:sms?) ? contacts.reject(&:voice?) : contacts
  end

  class << self
    def create_with_user(broadcastable: nil, user: nil, **args)
      org_user = broadcastable.organization_user_for(user)
      create!(args.merge(broadcastable: broadcastable, organization_user: org_user))
    end
  end
end