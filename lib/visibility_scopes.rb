module VisibilityScopes
  extend ActiveSupport::Concern

  included do
    scope :public, -> { where(visibility: :public) }
    scope :private, -> { where(visibility: :private) }
  end

  def private?
    visibility == 'private'
  end

  def public?
    !private?
  end

end