module EmailVerifiable
  def self.prepended(mod)
    mod.send(:before_create, :disable_confirmation, unless: :unverified?)
    mod.send(:devise, :confirmable, :async, reconfirmable: false, confirmation_keys: [:description])
  end

  def confirmed?
    verified?
  end

  def after_confirmation
    change_status(:verified)
  end

  private

  def disable_confirmation
    skip_confirmation_notification!
  end
end