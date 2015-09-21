class Resource < ActiveRecord::Base
  include Identifiable
  include IdGenerator
  include VisibilityScopes

  # before_destroy :destroy_organizations, unless: :skip_destroy_organizations
  before_validation :set_uniqueid, on: :create

  has_many :organization_resources, dependent: :destroy
  has_many :organizations, through: :organization_resources

  validates_presence_of :name
  validates_length_of :name, maximum: 50

  scope :typeahead_order, -> { order(:uniqueid).limit(10) }
  scope :typeahead_select, -> { select(:uniqueid, :name) }
  scope :by_uniqueid, -> (uniqueid) { where(uniqueid: uniqueid) }

  attr_accessor :skip_destroy_organizations

  def destroy_without_checks
    self.skip_destroy_organizations = true
    destroy
  end

  private

  def destroy_organizations
    organizations.each { |o| o.destroy_without_checks(:resources) if o.resources == [self] }
    true
  end

  def set_uniqueid
    self.uniqueid = Resource.make_unique(Resource.clean(self.name), Resource) if self.name.present? && self.uniqueid.blank?
  end

end