class AddInboundNumerToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :inbound_number_id, :integer
    add_index :requests, :inbound_number_id
  end
end
