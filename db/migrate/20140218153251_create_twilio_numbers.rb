class CreateTwilioNumbers < ActiveRecord::Migration
  def change
    create_table :twilio_numbers do |t|
      t.string :number
    end
    add_index :twilio_numbers, :number
  end
end
