class AddUniqueIndexToShareLinksToken < ActiveRecord::Migration[8.1]
  def change
    add_index :share_links, :token, unique: true, if_not_exists: true
  end
end
