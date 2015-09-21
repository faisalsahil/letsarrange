class Mapping < ActiveRecord::Base
  include StateScopes

  belongs_to :user
  belongs_to :entity, polymorphic: true, foreign_key: :entity_id, foreign_type: :entity_type

  validates :user, presence: true
  validates :entity, presence: true
  validates :user_id, uniqueness: { scope: [:endpoint_id, :entity_id, :entity_type, :status] }
  validates :entity_type, inclusion: { in: %w(LineItem InboundNumber) }

  before_create :generate_code

  scope :for_entity, ->(entity) { where(entity_id: entity.id, entity_type: entity.class.to_s) }

  add_status_with MappingState

  alias_method :line_item, :entity
  alias_method :inbound_number, :entity

  def close
    change_status(:closed)
  end

  def self.mapping_for(user, entity)
    active.for_entity(entity).find_by(user: user)
  end
end