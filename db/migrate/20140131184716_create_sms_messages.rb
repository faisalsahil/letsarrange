class CreateSmsMessages < ActiveRecord::Migration
  def change
    create_table :sms_messages do |t|
      t.string :sid
      t.datetime :date_sent
      t.string :to
      t.string :from
      t.string :body
	    t.string :status      
      t.string :uri
      t.integer :broadcast_id

      t.timestamps
    end

    add_index :sms_messages, :to
    add_index :sms_messages, :broadcast_id
  end
end