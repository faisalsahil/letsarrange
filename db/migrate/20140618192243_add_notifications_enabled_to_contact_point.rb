class AddNotificationsEnabledToContactPoint < ActiveRecord::Migration
  def change
    add_column :contact_points, :notifications_enabled, :boolean

    ContactPoint::Sms.where(status: [ContactPointState::VERIFIED, 5]).update_all(status: ContactPointState::VERIFIED, notifications_enabled: true)
    ContactPoint::Email.where(status: [ContactPointState::VERIFIED, 5]).update_all(status: ContactPointState::VERIFIED, notifications_enabled: true)
    User.find_each(&:ensure_preferred_voice)
  end
end
