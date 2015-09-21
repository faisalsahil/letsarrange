class ChangeDefaultVisibilityForOrganization < ActiveRecord::Migration
  def change
    change_column :organizations, :visibility, :string, default: 'private'
  end
end
