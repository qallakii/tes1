class AddForcePasswordChangeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :force_password_change, :boolean, default: false, null: false
    add_index :users, :force_password_change
  end
end
