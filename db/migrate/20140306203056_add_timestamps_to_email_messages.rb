class AddTimestampsToEmailMessages < ActiveRecord::Migration
  def change
    change_table(:email_messages) { |t| t.timestamps }
  end
end
