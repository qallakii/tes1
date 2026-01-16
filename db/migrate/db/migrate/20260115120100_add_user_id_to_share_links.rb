class AddUserIdToShareLinks < ActiveRecord::Migration[7.0]
  def change
    add_reference :share_links, :user, foreign_key: true, null: true
  end
end
