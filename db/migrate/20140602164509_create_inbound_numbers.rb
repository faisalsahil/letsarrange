class CreateInboundNumbers < ActiveRecord::Migration
  def change
    create_table :inbound_numbers do |t|
      t.string :number
    end

    add_index :inbound_numbers, :number
  end
end
