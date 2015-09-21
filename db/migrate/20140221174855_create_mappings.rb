class CreateMappings < ActiveRecord::Migration
  def change
    create_table :mappings do |t|
      t.integer :user_id
      t.integer :endpoint_id
      t.integer :entity_id
      t.string :entity_type
      t.string :code
      t.integer :status, default: 0
      t.string :type

      t.timestamps
    end

    add_index :mappings, :user_id
    add_index :mappings, :endpoint_id
    add_index :mappings, :code
    add_index :mappings, :entity_id
  end
end