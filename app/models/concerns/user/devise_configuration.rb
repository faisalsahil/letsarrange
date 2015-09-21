class User
  module DeviseConfiguration
    extend ActiveSupport::Concern

    included do
      attr_accessor :login # virtual parameter for Devise
      before_create :skip_email_confirmation
    end

    def email_required?
      false
    end

    def email_changed?
      false
    end

    def skip_email_confirmation
      self.skip_confirmation!
    end

    module ClassMethods
      def find_for_authentication(warden_conditions)
        conditions = warden_conditions.dup
        conditions[:uniqueid] = clean(conditions.delete(:login))
        find_first_by_auth_conditions(conditions)
      end
    end
  end
end