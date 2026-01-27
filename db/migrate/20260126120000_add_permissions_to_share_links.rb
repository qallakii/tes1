class AddPermissionsToShareLinks < ActiveRecord::Migration[7.0]
  def change
    # Permissions for shared links
    add_column :share_links, :allow_preview,  :boolean, null: false, default: true
    add_column :share_links, :allow_download, :boolean, null: false, default: true
    add_column :share_links, :require_login,  :boolean, null: false, default: false

    add_index :share_links, :require_login
  end
end
