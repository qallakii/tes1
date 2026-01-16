class MakeShareLinksFolderIdNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :share_links, :folder_id, true
  end
end
