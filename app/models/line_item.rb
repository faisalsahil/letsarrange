class LineItem < ActiveRecord::Base
  belongs_to :request, inverse_of: :line_items
  has_one :requesting_organization, through: :request, source: :organization
  has_one :requesting_org_resource, through: :request, source: :organization_resource
  belongs_to :organization_resource
  has_one :resource, through: :organization_resource
  has_one :requested_organization, through: :organization_resource, source: :organization
  belongs_to :last_edited, class_name: :OrganizationUser
  belongs_to :created_for, class_name: :OrganizationUser
  with_options dependent: :destroy do |a|
    a.has_many :broadcasts, as: :broadcastable
    a.has_many :mappings, as: :entity
    a.has_many :phone_mappings, as: :entity
  end
  alias_attribute :requested_org_resource, :organization_resource

  validates_presence_of :organization_resource, :request, :created_for
  validates_associated :organization_resource

  before_create :populate_from_parent
  before_save :reopen_request
  after_destroy :destroy_request, :destroy_url_mappings
  after_save :create_missing_mappings, if: :created_for_id_changed?

  attr_accessor :line_change, :comment

  delegate :time_zone, :humanized_messages?, :systemized_messages?, :created_by, :author, to: :request
  scope :including_associations, -> { includes(:request, :broadcasts, :requesting_organization, :requested_organization, :resource) }
  scope :open, -> { where.not(status: [LineItemState::ACCEPTED, LineItemState::CLOSED]) }

  attrs_in_tmz :earliest_start, :finish_by, :ideal_start
  add_status_with LineItemState, soft_delete: true

  accepts_nested_attributes_for :organization_resource

  include Schedulable

  def edited_by_name
    last_edited ? last_edited.full_name : '-'
  end

  def created_by_name
    created_by.full_name
  end

  def created_for_name
    created_for.full_name
  end

  def to_sentence_segments(without_with: false, without_from: false, and_for_between: true)
    sentence = {}
    sentence[:from] = "#{ requesting_organization.name }:" unless without_from

    if description.present?
      sentence[:description] = description
      sentence.merge!(common_fields(without_with))
      sentence[:length] = "for #{ LengthHelper.format(length) }" if length.present?
    else
      if length.present?
        sentence[:length] = LengthHelper.format(length)
      else
        sentence[:description] = 'time'
      end
      sentence.merge!(common_fields(without_with))
    end

    if earliest_start.present? || finish_by.present?
      sentence.merge!(and_for_between ? ScheduleLineItemText.to_segments(earliest_start,finish_by, time_zone) : { timeframe: ScheduleLineItemText.to_sentence(earliest_start,finish_by, time_zone) })
    end
    sentence.merge!(IdealLineItemText.new(self).to_segments) if ideal_start.present?

    sentence[:offer] = "offering #{ offer }" if offer.present?
    sentence[:comment] = "- #{ comment }" if comment.present?
    sentence
  end

  def to_sentence(**args)
    to_sentence_segments(**args.merge(and_for_between: false)).values * ' '
  end

  def humanized_wording_status
    MessageBrandingState::HUMANIZED_WORDING[humanized_status]
  end

  def to_humanized_sentence
    sentence = []
    if description.present?
      sentence << "Can I get #{description}"
      sentence.concat(common_fields(false).values)
      sentence << "for #{ LengthHelper.format(length) }" if length.present?
    else
      sentence << "Can I get " + (length.present? ? LengthHelper.format(length) : "time")
      sentence.concat(common_fields(false).values)
    end

    sentence << ScheduleLineItemText.to_sentence(earliest_start,finish_by, time_zone) if earliest_start.present? or finish_by.present?
    sentence << IdealLineItemText.new(self).to_sentence if ideal_start.present?

    sentence << "for #{ offer }." if offer.present?
    sentence[sentence.length-1] = sentence.last + '?' if description.present?
    sentence << "#{ comment } " if comment.present?
    sentence * ' '
  end

  def common_fields(without_with)
    {}.tap do |common_fields|
      common_fields[:location] = "at #{ location }" if location.present?
      common_fields[:requesting_resource] = "for #{ requesting_org_resource.name }" if requesting_org_resource.name != 'anyone' && requesting_org_resource.name != request.created_by.try(:name)
      common_fields[:requested_resource] = "with #{ use_resource_full_name? ? organization_resource.full_name : organization_resource.name }" unless without_with
    end
  end

  def last_broadcast
    broadcasts.order(:id).last
  end

  def no_replies?
    broadcasts.size <= 1
  end

  def populate_from_parent
    %w(earliest_start finish_by ideal_start length description location last_edited_id offer comment).each do |field|
      send("#{ field }=", request.send(field)) if send(field).blank?
    end
  end

  def create_opening_broadcast(author)
    Broadcast.create_with_user(broadcastable: self, user: author, body: to_sentence(without_from: true))
  end

  def voice_number(pov_user)
    target = if pov_user == receiver
             author
           elsif pov_user == author
             receiver
           end
    target.try(:voice_number)
  end

  def target_org_resource(user)
    requesting_user?(user) ? requested_org_resource: requesting_org_resource
  end

  def caller_info(pov_user)
    if requesting_user?(pov_user)
      if request.reserved_number
        Caller.new(request.reserved_number)
      else
        Caller.new(receiver_mapping.twilio_number, organization_resource, requesting_organization.org_user_for(pov_user))
      end
    else
      Caller.new(author_mapping.twilio_number, organization_resource, requested_organization.org_user_for(pov_user))
    end
  end

  def close(broadcast_sender: nil, closing_message: nil, close_request: true)
    unless closed?
      LineItem.transaction do
        change_status(:closed)
        if broadcast_sender
          update_last_edited(broadcast_sender)
          create_custom_broadcast(broadcast_sender, closing_message)
        end
        request.close(broadcast_sender: broadcast_sender) if close_request && !request.line_items.open.exists?
        mappings.each(&:close)
      end
    end
  end

  def offered?
    status == LineItemState::OFFERED
  end

  def countered?
    status == LineItemState::COUNTERED
  end

  def closed?
    status == LineItemState::CLOSED
  end

  def accepted?
    status == LineItemState::ACCEPTED
  end

  def reopenable_by?(user)
    closed? && user.is_a_requester_of_line_item?(self)
  end

  def declinable_by?(user)
    !(accepted? || last_changed_by?(user))
  end

  def offerable_by?(user)
    accepted? || (offered? && last_changed_by?(user))
  end

  def acceptable_by?(user)
    accepted? || !last_changed_by?(user)
  end

  def new_status_on_update!(updated_by)
    new_status = if closed?
                   :offered
                 elsif accepted?
                   :offered if update_requires_confirmation?
                 else
                   unless last_changed_by?(updated_by)
                     update_requires_confirmation? ? :countered : :accepted
                   end
                 end
    change_status(new_status) if new_status
  end

  def body_with_status(body)
    "[#{ humanized_status }] #{ body }"
  end

  def update_last_edited(author)
    organization = author.is_a_requester_of_line_item?(self) ? requesting_organization : requested_organization
    self.last_edited = author.organization_user_for(organization.id)
    save!
  end

  def organization_user_for(user)
    requesting_organization_user(user) || requested_organization_user(user)
  end

  def requesting_organization_user(user)
    requesting_organization.org_user_for(user)
  end
  alias_method :requesting_user?, :requesting_organization_user

  def requested_organization_user(user)
    requested_organization.org_user_for(user)
  end
  alias_method :requested_user?, :requested_organization_user

  def receiver_mapping
    phone_mappings.active.find_by(user_id: receiver.id)
  end

  def author_mapping
    phone_mappings.active.find_by(user_id: author.id)
  end

  def resource_name(pov_user)
    target_org_resource(pov_user).name
  end

  def resource_full_name(pov_user)
    target_org_resource(pov_user).full_name
  end

  def title(pov_user = nil)
    resource_full_name(pov_user) if pov_user #hack for active_admin titles
  end

  def receiver
    created_for.user
  end

  def update_receiver(sender_number)
    new_receiver = User.find_or_create_user( { voice: sender_number, sms: sender_number }, ContactPoint::Phone.denormalized(sender_number), default_org_resource: organization_resource, without_org: true)
    requested_organization.add_user(new_receiver, status: OrganizationUserState::UNTRUSTED).tap do |new_created_for|
      update!(created_for: new_created_for)
    end
  end

  def change_receiver(user)
    org_user = requested_organization.org_user_for(user)
    update!(created_for: org_user) if org_user
  end

  def receiver_contacts
    receiver.notifiable_contacts(allow_unverified: true)
  end

  def author_contacts
    author.notifiable_contacts
  end

  def mail_prefix(pov_user)
    (requesting_user?(pov_user) ? requested_organization : requesting_organization).uniqueid
  end

  def mapping_path
    Rails.application.routes.url_helpers.request_line_item_path(request, self)
  end

  def accept(accepter)
    unless accepted?
      LineItem.transaction do
        change_status(:accepted)
        update_last_edited(accepter)
        change_receiver(accepter)
        create_custom_broadcast(accepter)
      end
    end
  end

  private

  def destroy_request
    request.destroy unless request.line_items.present?
    true
  end

  def destroy_url_mappings
    UrlMapping.with_path(:request_line_item_path, request, self).find_each(&:destroy)
    true
  end

  def reopen_request
    request.reopen if offered? && was_closed?
  end

  def was_closed?
    status_was == LineItemState::CLOSED
  end

  def last_changed_by?(user)
    last_edited.shares_organization?(user)
  end

  def update_requires_confirmation?
    time_window_broadened? || changes.except(:last_edited_id, :earliest_start, :ideal_start, :finish_by).any? { |_, values| values.first.present? }
  end

  def time_window_broadened?
    (earliest_start_was && (!earliest_start || earliest_start < earliest_start_was)) ||
        (finish_by_was && (!finish_by || finish_by > finish_by_was))
  end

  def create_custom_broadcast(author, message = nil)
    Broadcast.create_with_user(broadcastable: self, user: author, body: body_with_status(message))
  end

  def create_missing_mappings
    receiver.create_mappings(self, systemized_messages?)
  end

  def use_resource_full_name?
    receiver.multiple_organizations? && created_for.name != requested_organization.name
  end

  def self.new_from_request(request)
    new do |li|
      li.request = request
      li.populate_from_parent
    end
  end

  def self.accept_via_ivr(broadcast_id, contact_id)
    line_item = Broadcast.find(broadcast_id).line_item
    accepter = ContactPoint.find(contact_id).user
    line_item.accept(accepter)
    VoiceBroadcastSender::ACCEPTED_MESSAGE
  end

  def self.close_via_ivr(broadcast_id, contact_id)
    line_item = Broadcast.find(broadcast_id).line_item
    closer = ContactPoint.find(contact_id).user
    line_item.close(broadcast_sender: closer)
    VoiceBroadcastSender::DECLINED_MESSAGE
  end
end