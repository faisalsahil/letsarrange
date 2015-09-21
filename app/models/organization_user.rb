class OrganizationUser < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user, inverse_of: :organizations
  has_many :broadcasts, dependent: :destroy

  validates_presence_of :user, :organization, :name
  validates_uniqueness_of :name, scope: :organization_id
  validates_length_of :name, maximum: 50

  after_destroy :destroy_user, :destroy_organization

  include IdGenerator
  include VisibilityScopes

  scope :trusted, -> { where(status: OrganizationUserState::TRUSTED) }

  add_status_with OrganizationUserState

  def full_name
    name == organization.name ? name : "#{ name } at #{ organization.name }"
  end

  def shares_organization?(another_user)
    organization.has_user?(another_user)
  end

  def trusted?
    status == OrganizationUserState::TRUSTED
  end

  def untrusted?
    status == OrganizationUserState::UNTRUSTED
  end

  def set_as_trusted
    change_status(:trusted)
  end

  private

  def destroy_user
    # TODO: probably use soft_delete or something similar to soft-delete in cascade as well
    user.destroy unless user.organization_users.present?
    true
  end

  def destroy_organization
    # TODO: probably use soft_delete or something similar to soft-delete in cascade as well
    organization.destroy unless organization.organization_users.present?
    true
  end

  class << self
    def create_or_update_with(organization: organization, user: user, name: name)
      orguser = find_or_create_by(organization: organization, user: user)
      orguser.update(name: name)
      orguser
    end

    def name_for(organization: organization, user: user)
      find_by(organization_id: organization, user_id: user).try(:name)
    end
  end
end