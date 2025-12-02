class CreateShareLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :share_links do |t|
      t.string :token
      t.references :folder, null: false, foreign_key: true
      t.datetime :expires_at

      t.timestamps
    end
  end
end
