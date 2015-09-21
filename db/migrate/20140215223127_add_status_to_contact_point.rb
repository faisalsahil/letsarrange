class AddStatusToContactPoint < ActiveRecord::Migration
  def change
    add_column :contact_points, :status, :integer, default: 0

    ContactPoint.find_each do |c|
      c.status = ContactPointState::VERIFIED if c.confirmed_at
      c.save(validate: false)
    end
  end
end
