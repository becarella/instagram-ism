class AddFeaturedToMedia < ActiveRecord::Migration
  def change
    add_column :media, :featured_at, :timestamp
  end
end
