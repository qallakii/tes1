class AddTitleAndDescriptionToCvs < ActiveRecord::Migration[8.1]
  def change
    add_column :cvs, :title, :string unless column_exists?(:cvs, :title)
    add_column :cvs, :description, :text unless column_exists?(:cvs, :description)
  end
end
