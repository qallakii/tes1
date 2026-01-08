class AddMetadataToCvs < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:cvs, :description)
      add_column :cvs, :description, :text
    end
  end
end
