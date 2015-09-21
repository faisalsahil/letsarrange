class AddVoiceResetToUsers < ActiveRecord::Migration
  def change
    add_column :users, :voice_reset_contact_id, :integer
    add_column :users, :voice_reset_code, :string
  end
end
