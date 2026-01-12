class CreateShareLinkFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :share_link_folders do |t|
      t.references :share_link, null: false, foreign_key: true
      t.references :folder, null: false, foreign_key: true
      t.timestamps
    end

    add_index :share_link_folders, [:share_link_id, :folder_id], unique: true
  end
end
