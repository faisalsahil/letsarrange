class AddOutgoingCallerSidToContactPoints < ActiveRecord::Migration
  def change
    add_column :contact_points, :outgoing_caller_sid, :string
    add_index :contact_points, :outgoing_caller_sid
  end
end
