class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :name
      t.string :uniqueid
      t.string :visibility, default: "public"
      t.timestamps
    end

    add_index :resources, :uniqueid
  end
end
