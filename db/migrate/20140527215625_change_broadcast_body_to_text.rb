class ChangeBroadcastBodyToText < ActiveRecord::Migration
  def change
    change_column :broadcasts, :body, :text
  end
end
