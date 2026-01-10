class AddConstraintsToShareLinks < ActiveRecord::Migration[8.1]
  def up
    # Backfill tokens for any existing rows that are missing them
    execute <<~SQL
      UPDATE share_links
      SET token = md5(random()::text)
      WHERE token IS NULL OR token = '';
    SQL

    change_column_null :share_links, :token, false
    add_index :share_links, :token, unique: true
  end

  def down
    remove_index :share_links, :token if index_exists?(:share_links, :token)
    change_column_null :share_links, :token, true
  end
end
