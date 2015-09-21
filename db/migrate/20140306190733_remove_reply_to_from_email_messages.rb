class RemoveReplyToFromEmailMessages < ActiveRecord::Migration
  def change
    EmailMessage.find_each do |e|
      unless e.from
        e.from = e.reply_to
        e.save
      end
    end
    remove_column :email_messages, :reply_to
  end
end
