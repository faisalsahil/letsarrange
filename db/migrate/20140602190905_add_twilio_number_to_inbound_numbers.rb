class AddTwilioNumberToInboundNumbers < ActiveRecord::Migration
  def change
    add_column :inbound_numbers, :twilio_number_id, :integer
    add_index :inbound_numbers, :twilio_number_id
  end
end
