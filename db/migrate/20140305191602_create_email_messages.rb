class CreateEmailMessages < ActiveRecord::Migration
  def change
    create_table :email_messages do |t|
      t.integer :broadcast_id
      t.string :uid
      t.string :to
      t.string :from
      t.string :reply_to
      t.text :body
      t.string :subject
    end

    add_index :email_messages, :broadcast_id
    add_index :email_messages, :uid
  end
end
