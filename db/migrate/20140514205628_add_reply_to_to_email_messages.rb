class AddReplyToToEmailMessages < ActiveRecord::Migration
  def change
    add_column :email_messages, :reply_to, :string
  end
end
