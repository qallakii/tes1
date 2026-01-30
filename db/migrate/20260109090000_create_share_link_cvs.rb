class CreateShareLinkCvs < ActiveRecord::Migration[8.1]
  def change
    create_table :share_link_cvs do |t|
      t.references :share_link, null: false, foreign_key: true
      t.references :cv, null: false, foreign_key: true

      t.timestamps
    end

    add_index :share_link_cvs, [ :share_link_id, :cv_id ], unique: true
  end
end
