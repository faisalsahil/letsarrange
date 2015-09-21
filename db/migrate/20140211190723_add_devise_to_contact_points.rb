class AddDeviseToContactPoints < ActiveRecord::Migration
  def self.up
    change_table(:contact_points) do |t|
      ## Confirmable
       t.string   :confirmation_token
       t.datetime :confirmed_at
       t.datetime :confirmation_sent_at
    end

    add_index :contact_points, :confirmation_token,   :unique => true
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
