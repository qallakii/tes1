class AddParentIdToFolders < ActiveRecord::Migration[7.1]
  def change
    add_reference :folders, :parent, foreign_key: { to_table: :folders }, index: true, null: true
  end
end
