class Request < ActiveRecord::Base
  include ErrorsSentence
  include Schedulable

  has_many :line_items, inverse_of: :request, dependent: :destroy
  has_many :inbound_numbers, dependent: :destroy
  has_many :requested_organizations, through: :line_items
  belongs_to :organization_resource
  has_one :organization, through: :organization_resource
  belongs_to :last_edited, class_name: :OrganizationUser
  belongs_to :created_by, class_name: :OrganizationUser
  belongs_to :contact_point, inverse_of: :requests
  belongs_to :reserved_number, class_name: :TwilioNumber

  validates_presence_of :organization, :time_zone
  validates_associated :organization, :line_items

  accepts_nested_attributes_for :line_items, reject_if: :all_blank, allow_destroy: true

  attrs_in_tmz :earliest_start, :finish_by, :ideal_start
  add_status_with RequestState, soft_delete: true

  attr_accessor :line_change, :comment

  scope :open, -> { where.not(status: RequestState::CLOSED) }
  scope :with_reserved_number, -> { where.not(reserved_number_id: nil ) }

  after_initialize :set_default_values

  def request
    self
  end

  def broadcasts
    Broadcast.of_inbound_numbers(inbound_numbers)
  end

	def title(without_from: false)
		LineItem.new_from_request(self).to_sentence(without_with: true, without_from: without_from)
  end

  def closed?
    status == RequestState::CLOSED
  end

  def reopen
    change_status(:offered)
  end

  def close(user)
    if closed?
      errors.add(:base, 'Request already closed')
    else
      close_dependencies(broadcast_sender: user)
    end
  end

  def close_dependencies(broadcast_sender: nil)
    Request.transaction do
      line_items.open.each { |li| li.close(broadcast_sender: broadcast_sender, close_request: false) }
      inbound_numbers.each(&:close)
      self.reserved_number = nil
      change_status(:closed)
    end
  end

  def closable_by?(user)
    organization.has_user?(user)
  end

  def humanized_messages?
    message_branding == MessageBrandingState::HUMANIZED
  end

  def systemized_messages?
    message_branding == MessageBrandingState::SYSTEMIZED
  end

  def assign_reserved_number(preferred_area_code)
    self.reserved_number = TwilioNumber.available_number(preferred_area_code) if humanized_messages?
  end

  def resource_name
    organization_resource.full_name
  end

  def line_item_of_requested_user(user)
    return nil unless user
    line_items.joins(:created_for).where(organization_users: { user_id: user.id }).first
  end

  def voice_number
    author.voice_number
  end

  def author
    created_by.user
  end

  def one_line_item?
    line_items.count == 1
  end

  def first_line_item
    line_items.first
  end

  def receiver_for_reserved_message(from_contact)
    if one_line_item?
      first_line_item.tap do |li|
        li.update_receiver(from_contact.number)
        from_contact.user = li.receiver
      end
    else
      line_item_of_requested_user(from_contact.try(:user)) || InboundNumber.create_with_mapping!(from_contact.number, self)
    end
  end

  private

  def set_default_values
    self.length ||= '1:00'
  end

end