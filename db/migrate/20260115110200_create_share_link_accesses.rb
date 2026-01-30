class CreateShareLinkAccesses < ActiveRecord::Migration[7.1]
  def change
    create_table :share_link_accesses do |t|
      t.references :share_link, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :share_link_accesses, [ :share_link_id, :user_id ], unique: true
  end
end
