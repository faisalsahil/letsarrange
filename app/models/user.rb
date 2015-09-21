class User < ActiveRecord::Base
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :timeoutable,
         :confirmable,
         :lockable,
         timeout_in: 1.day, remember_for: 2.years, password_length: 6..128


  before_validation :build_organization_resource
  before_validation :build_organization_user, unless: :without_org
  before_save :normalize_login_information
  #callbacks should be the defined at the end, but rails treats dependent: :destroy as a before_destroy callback so order is important
  before_destroy :destroy_organizations, unless: :skip_destroy_organizations
  after_create :set_default_user

  with_options dependent: :destroy do |a|
    a.has_many :contact_points, inverse_of: :user
    a.has_many :organization_users, inverse_of: :user
    a.has_many :mappings
    a.has_many :phone_mappings
    a.has_many :email_mappings
  end
  belongs_to :default_org_resource, class_name: :OrganizationResource, foreign_key: :default_organization_resource_id
  has_many :organizations, through: :organization_users
  has_many :received_line_items, through: :organizations
  has_many :broadcasts, through: :organization_users
  has_one :default_org, through: :default_org_resource, source: :organization
  # orgs that has 'self' as their default_user
  has_many :orgs_as_default, class_name: :Organization, foreign_key: :default_user_id

  validates :website, length: { maximum: 250 }
  with_options presence: true do |v|
    v.validates :name, length: { maximum: 50 }
    v.validates :default_org_resource
    v.validates :organization_users, unless: :without_org
  end
  validate :created_with_phone, if: :phone_missing
  validates_associated :default_org_resource, :organization_users

  include DeviseConfiguration
  include IdGenerator
  include Identifiable
  include PasswordResetViaContacts
  include ErrorsSentence
  include VisibilityScopes

  scope :typeahead_order, -> { order(:uniqueid).limit(10) }
  scope :typeahead_select, -> { select(:uniqueid, :name) }
  scope :by_uniqueid, -> (uniqueid) { where(uniqueid: uniqueid) }
  scope :by_name, -> (name) { where(name: name) }

  delegate :sms, :email, :voice, :phone, to: :contact_points, prefix: :contacts

  accepts_nested_attributes_for :contact_points
  attr_accessor :phone_missing, :skip_destroy_organizations
  attr_accessor :resource_name, :resource_uniqueid, :organization_name, :organization_visibility, :without_org #This shouldn't be here

  def sorted_voices
    contacts_voice.order(:description)
  end

  def sorted_smss
    contacts_sms.order(:description)
  end

  def sorted_emails
    contacts_email.order(:description)
  end

  def contact_email
    contacts_email.first.try(:email)
  end

  def can_view_line_item?(line)
    is_a_resource_of_line_item?(line) || is_a_requester_of_line_item?(line)
  end

  def is_a_requester_of_line_item?(line)
    organizations.joins(requests: :line_items).where(line_items: { id: line.id }).exists?
  end

  def is_a_resource_of_line_item?(line)
    organizations.joins(organization_resources: :line_items).where(line_items: { id: line.id }).exists?
  end

  def matching_mappings(twilio_number)
    phone_mappings.active.for_twilio(twilio_number).order(:code)
  end

  def needs_code?(from_number)
    phone_mappings.active.for_twilio(from_number).count > 1
  end

  def mapping_for_entity(entity)
    phone_mappings.active.for_entity(entity).first
  end

  def can_make_requests?
    !!verified_phone
  end

  def organization_user_for(organization_id)
    organization_users.find_by(organization_id: organization_id)
  end

  def destroy_without_checks
    self.skip_destroy_organizations = true
    destroy
  end

  def preferred_area_code
    ContactPoint::Phone.area_code(verified_phone.number) if verified_phone
  end

  def verified_phone
    contacts_phone.verified.first
  end

  def manageable_organizations
    Organization.includes(:organization_users).merge(OrganizationUser.trusted).where(organization_users: { user: self })
  end

  def can_manage_organization?(organization)
    organization_users.trusted.where(organization: organization).exists?
  end

  def find_or_create_org(org_name)
    organizations.find_by(name: org_name) || Organization.create_by_name_and_user!(org_name, self, 'public')
  end

  def voice_number
    (preferred_voice || contacts_voice.trusted_or_verified.first).try(:number)
  end

  def notifiable_contacts(allow_unverified: false)
    preferred_contacts.presence || (allow_unverified ? contact_points.enabled : contact_points.trusted_or_verified)
  end

  def preferred_contacts
    contact_points.notifiable
  end

  def preferred_voice
    contacts_voice.notifiable.first
  end

  def ensure_preferred_voice(except_id = '-1')
    contacts_voice.verified.where.not(id: except_id).first.try(:enable_notifications) unless preferred_voice
  end

  def sorted_preferred_contacts
    preferred_contacts.order('type desc')
  end

  def managed_org_resources
    organizations.map(&:organization_resources).flatten
  end

  def managed_resources
    organizations.map(&:resources).flatten
  end

  def create_mappings(mappeable, include_phones)
    contacts = notifiable_contacts(allow_unverified: true)
    EmailMapping.create_for(self, mappeable) if contacts.any?(&:email?)
    PhoneMapping.create_for(self, mappeable) if include_phones && contacts.any?(&:phone?)
  end

  def avoid_default_org(organization)
    # update default org & org-resource if it was the one we're destroying
    if default_org == organization
      new_org          = organizations.where.not(id: organization.id).first
      new_org_resource = new_org.organization_resources.first
      update!(default_org_resource: new_org_resource)
    end
  end

  def multiple_organizations?
    organizations.size > 1
  end

  private

  def normalize_login_information
    uniqueid.downcase!
    email.downcase!
  end

  def build_organization_user
    return if organization_users.any? or !uniqueid or !name
    organization_users.build(organization: default_org_resource.organization, name: name)
  end

  def build_organization_resource
    return if default_org_resource or !uniqueid or !name

    self.resource_name ||= name

    org = Organization.new(uniqueid: uniqueid, name: organization_name || name, visibility: organization_visibility || 'private')
    resource = Resource.new(uniqueid: resource_uniqueid || uniqueid, name: resource_name || name)
    build_default_org_resource(organization: org, resource: resource, name: resource_name) 
  end

  def created_with_phone
    errors.add(:phone, "can't be blank")
  end

  def destroy_organizations
    organizations.each { |o| o.destroy_without_checks(:users) if o.users == [self] }
    true
  end

  def set_default_user
    default_org.default_user ||= self
  end

  class << self
    def find_or_create_user(contact_point, user_name, args = {})
      existing_user = User.find_user(contact_point).first
      if existing_user
        existing_user
      else
        new_user = User.create!( {
                          name: user_name,
                          uniqueid: make_unique(clean(contact_point.values.first), User),
                          organization_visibility: 'public' }.merge(args)) do |user|
          require 'securerandom'
          user.password = SecureRandom.hex
          user.resource_uniqueid = make_unique(OrganizationResource.resource_default_unique_id(user.uniqueid, args[:resource_name]), Resource) if args[:resource_name]
        end

        contact_point.each do |contact_type, description|
          type = ContactPoint.full_type(contact_type)
          unless  ContactPoint.exists?(type: type, description: description)
            new_user.contact_points << ContactPoint.new(type: type, description: description, status: ContactPointState::TRUSTED)
          end
        end

        new_user
      end
    end

    def find_user(contact_point)
      joins(:contact_points).where(contact_points: { description: contact_point.values })
    end

    def new_with_error(error_field, error_message)
      new.tap { |u| u.errors.add(error_field, error_message) }
    end
  end
end