class ChangeBodyLengthOfSmsMessages < ActiveRecord::Migration
  def change
    change_column :sms_messages, :body, :text
  end
end
