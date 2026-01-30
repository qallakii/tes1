class AddUserAndCommentToRatings < ActiveRecord::Migration[8.1]
  def change
    add_reference :ratings, :user, null: true, foreign_key: true
    add_column :ratings, :comment, :text

    # One rating per user per CV
    add_index :ratings, [ :cv_id, :user_id ], unique: true
  end
end
