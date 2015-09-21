class CreateUrlMappings < ActiveRecord::Migration
  def change
    create_table :url_mappings do |t|
      t.integer :contact_point_id
      t.string :code
      t.string :path
      t.integer :status, default: 0
    end

    add_index :url_mappings, :contact_point_id
    add_index :url_mappings, :code
  end
end
