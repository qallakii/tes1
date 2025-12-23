class AddUserIdToCvs < ActiveRecord::Migration[8.1]
  def change
    add_reference :cvs, :user, null: false, foreign_key: true
  end
end
