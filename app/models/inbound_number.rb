class InboundNumber < ActiveRecord::Base
  with_options as: :entity, dependent: :destroy do |h|
    h.has_many :mappings
    h.has_many :phone_mappings
    h.has_many :email_mappings
  end
  has_many :broadcasts, as: :broadcastable
  belongs_to :request

  validates :number, presence: true, format: { with: /\A\d+\z/ }, uniqueness: { scope: :request_id }
  validates :request, presence: true

  delegate :author, to: :request, prefix: true

  def voice_number(_)
    number
  end
  alias_method :resource_full_name, :voice_number
  alias_method :resource_name, :voice_number
  alias_method :mail_prefix, :voice_number

  def caller_info(_)
    Caller.new(request.reserved_number)
  end

  def transfer_broadcasts(new_broadcastable, new_author)
    broadcasts.each { |b| b.update!(broadcastable: new_broadcastable, organization_user: new_author) }
  end

  def author_mapping
    phone_mappings.active.find_by(user_id: request_author.id)
  end

  def organization_user_for(user)
    request.created_by if user && requesting_user?(user)
  end

  def requesting_user?(user)
    request_author == user
  end

  def receiver_contacts
    [ContactPoint::Sms.new(description: number)]
  end

  def author_contacts
    request_author.notifiable_contacts
  end

  def no_replies?
    false
  end

  def mapping_path
    Rails.application.routes.url_helpers.request_path(request)
  end

  def merge_into(line_item_id)
    InboundNumber.transaction do
      new_broadcastable = line_item_id && request.line_items.find_by(id: line_item_id)
      if new_broadcastable
        new_author = new_broadcastable.update_receiver(number)
        transferred_broadcasts = transfer_broadcasts(new_broadcastable, new_author)
        destroy
        transferred_broadcasts
      end
    end
  end

  def close
    mappings.each(&:close)
  end

  private

  def self.create_with_mapping!(number, request)
    transaction do
      inbound = find_or_create_by!(number: number, request: request)
      request.author.create_mappings(inbound, true)
      inbound
    end
  end
end