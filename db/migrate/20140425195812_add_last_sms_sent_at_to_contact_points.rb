class AddLastSmsSentAtToContactPoints < ActiveRecord::Migration
  def change
    add_column :contact_points, :last_sms_sent_at, :datetime
  end
end
