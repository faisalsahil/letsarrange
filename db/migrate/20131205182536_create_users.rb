class CreateUsers < ActiveRecord::Migration
  def change
  	create_table :users do |t|
      t.timestamps

      #START DEVISE COLUMNS 

      ## Database authenticatable
      t.string :email,              :null => true, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0, :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      #END DEVISE

      t.string :name
      t.string :uniqueid
      t.string :website
      t.boolean :admin, default: false
      t.string :visibility, default: "public"
      t.integer :default_org_id 
      t.integer :default_resource_id
      t.integer :sms_sent_to_user_state, default: 0
      t.integer :sms_received_from_user_state, default: 0

      t.timestamps
    end

    add_index :users, :uniqueid, unique: true
    add_index :users, :email                
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :name         
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :unlock_token,         :unique => true
  end
end
