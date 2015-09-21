class Organization < ActiveRecord::Base
  before_create :normalize_orgid
  before_destroy :destroy_orphaned

  with_options dependent: :destroy do |h|
    h.has_many :organization_users
    h.has_many :organization_resources
  end
  has_many :users, through: :organization_users
  has_many :resources, through: :organization_resources
  has_many :received_line_items, through: :organization_resources, source: :line_items
  has_many :requests, through: :organization_resources
  has_many :line_items, through: :requests

  belongs_to :default_user, class_name: :User

  validates_length_of :name, maximum: 50
  validates_presence_of :name

  include Identifiable
  include IdGenerator
  include VisibilityScopes

  scope :typeahead_order, -> { order(:uniqueid).limit(10) }
  scope :typeahead_select, -> { select(:uniqueid, :name) }
  scope :by_uniqueid, -> (uniqueid) { where(uniqueid: uniqueid) }
  scope :by_name, -> (name) { where(name: name) }

  attr_accessor :destroy_source


  # == Class methods

  class << self
    # create organization based on 'name' param. Assigns 'default_user' as the default_user for the new
    # organization created. You can also set visibility (default is 'private') and org's user name which
    # will be default to default_user's name if not given
    def create_by_name_and_user!(name, default_user, default_visibility='private', org_user_name=nil)
      create!(uniqueid: make_unique(clean(name), self),
              name: name,
              visibility: default_visibility,
              default_user: default_user).tap do |org|
                org.add_user(default_user, name: org_user_name)
              end
    end

    def create_with_user(attrs, default_user, org_user_name=nil)
      create(attrs.merge(default_user: default_user)).tap do |org|
        org.add_user(default_user, name: org_user_name)
      end
    end
  end


  # == Instance methods

  def add_user(user, attrs = {})
    attrs[:name] ||= user.name
    organization_users.where(user: user).first_or_create!(attrs)
  end

  def add_resource(resource, name=nil)
    organization_resources.where(resource: resource).first_or_create do |org_resource|
      org_resource.name = (name || resource.name)
    end
  end

  def destroy_without_checks(source)
    self.destroy_source = source
    destroy
  end

  def org_user_for(user)
    organization_users.find_by(user: user) if user
  end
  alias_method :has_user?, :org_user_for

  def default_organization_user
    organization_users.find_by(user: default_user)
  end

  def can_be_destroyed_by?(user)
    # true ONLY if ALL its org-resources can be unlinked by user
    organization_resources.reduce(true) {|accum,org_res| accum && org_res.can_be_unlinked_by?(user)}
  end

  def avoid_default_user(user)
    # update default user if it was the one we're destroying
    if default_user == user
      new_user = users.where.not(id: user.id).first
      update!(default_user: new_user)
    end
  end

  private

  def normalize_orgid
    self.uniqueid = Organization.clean(self.uniqueid)
  end

  def destroy_orphaned
    [:users, :resources].each do |association|
      send(association).each { |item| item.destroy_without_checks if item.organizations == [self] } unless destroy_source == association
    end
    true
  end

end
