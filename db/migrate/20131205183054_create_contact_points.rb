class CreateContactPoints < ActiveRecord::Migration
  def change
    create_table :contact_points do |t|
      t.string :contact_type
      t.integer :user_id
      t.string :description
      t.timestamps
    end

    add_index :contact_points, [:user_id, :contact_type]
  end
end
