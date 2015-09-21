class ChangeDefaultValueForMessageBranding < ActiveRecord::Migration
  def up
    change_column_default :requests, :message_branding, 0
  end
  def down
    change_column_default :requests, :message_branding, 1
  end
end
