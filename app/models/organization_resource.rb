class OrganizationResource < ActiveRecord::Base
  belongs_to :organization
  belongs_to :resource

  validates_associated :resource
  validates_presence_of :resource, :organization, :name
  validates_uniqueness_of :name, scope: :organization_id
  validates_length_of :name, maximum: 50

  # TODO: [WARNING] this dependent destroys should be performed via 'soft_delete'!!!
  with_options dependent: :destroy do |a|
    a.has_many :line_items  # line items received
    a.has_many :requests    # requests made
  end
  # users that has 'self' OrganizationResource as their default
  has_many :users_as_default, class_name: :User, foreign_key: :default_organization_resource_id

  after_destroy :destroy_resource

  include IdGenerator
  include VisibilityScopes

  delegate :uniqueid, prefix: :org, to: :organization

  def full_name
    organization.name == name ? name : "#{ name } from #{ organization.name }"
  end

  def can_be_unlinked_by?(author)
    # nobody has self as default org-resource, OR
    # there's ONLY ONE user that has self as default org-resource and it's equal to 'author'
    (users_as_default.size == 0) ||
    ((users_as_default.size == 1) && (users_as_default.first == author))
  end

  class << self
    def find_or_create_within_org(org, resource_name)
      org.organization_resources.where(name: resource_name).first_or_create do |org_resource|
        uniqueid = make_unique(resource_default_unique_id(org.uniqueid, resource_name), Resource)
        org_resource.build_resource uniqueid: uniqueid, name: resource_name
      end
    end

    def resource_default_name(resource_name)
      resource_name.presence || 'anyone'
    end

    def resource_default_unique_id(org_uniqueid, resource_name)
      resource_name = resource_default_name(resource_name)
      "#{ org_uniqueid }-#{ clean(resource_name) }"
    end
  end


  private

  def destroy_organization
    # TODO: probably use soft_delete or something similar to soft-delete in cascade as well
    organization.destroy unless organization.organization_resources.present?
    true
  end

  def destroy_resource
    # TODO: probably use soft_delete or something similar to soft-delete in cascade as well
    resource.destroy if resource && resource.organization_resources.blank?
    true
  end

end