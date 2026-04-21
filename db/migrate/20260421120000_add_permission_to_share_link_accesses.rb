class AddPermissionToShareLinkAccesses < ActiveRecord::Migration[8.1]
  def change
    add_column :share_link_accesses, :permission, :string, null: false, default: "viewer"
    add_index :share_link_accesses, :permission
  end
end
