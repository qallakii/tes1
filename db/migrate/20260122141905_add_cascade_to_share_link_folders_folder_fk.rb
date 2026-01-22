class AddCascadeToShareLinkFoldersFolderFk < ActiveRecord::Migration[8.1]
  def up
    # Remove existing FK (name in your error: fk_rails_4294099bbc)
    remove_foreign_key :share_link_folders, name: :fk_rails_4294099bbc

    # Re-add with cascade
    add_foreign_key :share_link_folders, :folders, on_delete: :cascade
  end

  def down
    remove_foreign_key :share_link_folders, :folders
    add_foreign_key :share_link_folders, :folders
  end
end
