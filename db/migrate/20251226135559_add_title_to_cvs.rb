class AddTitleToCvs < ActiveRecord::Migration[8.1]
  def change
    add_column :cvs, :title, :string
  end
end
