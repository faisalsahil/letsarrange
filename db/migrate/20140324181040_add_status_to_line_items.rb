class AddStatusToLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :status, :integer, default: LineItemState::OFFERED
  end
end
