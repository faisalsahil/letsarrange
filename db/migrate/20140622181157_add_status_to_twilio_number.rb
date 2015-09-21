class AddStatusToTwilioNumber < ActiveRecord::Migration
  def change
    add_column :twilio_numbers, :status, :integer, default: TwilioNumberState::ACTIVE
  end
end
