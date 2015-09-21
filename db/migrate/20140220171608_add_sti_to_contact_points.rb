class AddStiToContactPoints < ActiveRecord::Migration
  def change
    rename_column :contact_points, :contact_type, :type
    execute("UPDATE contact_points SET type = (CASE type WHEN 'sms' THEN 'ContactPoint::Sms' WHEN 'voice' THEN 'ContactPoint::Voice' WHEN 'email' THEN 'ContactPoint::Email' END)")
  end
end
