module Identifiable
	extend ActiveSupport::Concern

	included do
    validates :uniqueid, presence: :true,
                         uniqueness: true,
                         length: { maximum: 50},
                         format: { with: /\A[a-z0-9\-]*\z/i, message: 'only letters, numbers, and "-" allowed' }
	end
end