class AddMetricsToFolders < ActiveRecord::Migration[8.1]
  def change
    add_column :folders, :bytes_cached, :bigint, default: 0, null: false unless column_exists?(:folders, :bytes_cached)
    add_column :folders, :items_cached, :integer, default: 0, null: false unless column_exists?(:folders, :items_cached)
    add_column :folders, :cached_at, :datetime unless column_exists?(:folders, :cached_at)
  end
end
