class BackfillShareLinksUserId < ActiveRecord::Migration[7.0]
  def up
    # If older share_links had folder_id, backfill user_id from that folder
    if column_exists?(:share_links, :folder_id)
      execute <<~SQL
        UPDATE share_links
        SET user_id = folders.user_id
        FROM folders
        WHERE share_links.folder_id = folders.id
          AND share_links.user_id IS NULL;
      SQL
    end
  end

  def down
    # no-op
  end
end
