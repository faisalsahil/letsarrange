class RenameInboundNumberToReservedNumber < ActiveRecord::Migration
  def change
    rename_column :requests, :inbound_number_id, :reserved_number_id
  end
end
