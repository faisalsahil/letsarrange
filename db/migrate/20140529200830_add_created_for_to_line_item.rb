class AddCreatedForToLineItem < ActiveRecord::Migration
  def change
    add_column :line_items, :created_for_id, :integer
    add_index :line_items, :created_for_id

    LineItem.find_each do |li|
      li.created_for = li.requested_organization.organization_users.first
      li.save(validate: false)
    end
  end
end
