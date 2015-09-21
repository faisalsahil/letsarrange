module StatusProvider
  def add_status_with(enum_klass, opts = {})
    define_singleton_method :status_provider do
      enum_klass
    end
    define_method :status_provider do
      enum_klass
    end

    include InstanceMethods
    include SoftDelete if opts[:soft_delete]
  end

  module InstanceMethods
    def humanized_status
      status_provider::HUMANIZED[status]
    end

    private

    def change_status(new_status)
      new_status = status_provider.const_get(new_status.upcase)
      if status_provider::TRANSITIONS[status].include?(new_status)
        self.status = new_status
        save(validate: false)
      end
    end
  end

  module SoftDelete
    extend ActiveSupport::Concern

    included do
      exclude_deleted = -> { where.not(status: status_provider::DELETED) }
      default_scope(&exclude_deleted)
      scope :without_deleted, exclude_deleted
      scope :with_deleted, -> { unscoped }
    end

    def soft_destroy
      run_callbacks :destroy do
        change_status(:deleted)
      end
    end
  end
end