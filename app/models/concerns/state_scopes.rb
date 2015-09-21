module StateScopes
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(status: MappingState::ACTIVE) }
    scope :closed, -> { where(status: MappingState::CLOSED) }
  end
end