class AddSecurityToShareLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :share_links, :password_digest, :string
    add_column :share_links, :disabled, :boolean, default: false, null: false
    add_column :share_links, :views_count, :integer, default: 0, null: false
    add_column :share_links, :last_viewed_at, :datetime
  end
end

