class CreateMedia < ActiveRecord::Migration
  def change
    create_table :media do |t|
      t.string :author_username
      t.string :author_name
      t.string :type
      t.string :source_id
      t.string :content_url
      t.string :page_url
      t.integer :content_width
      t.integer :content_height
      t.timestamp :posted_at
      t.text :caption
      t.integer :location_id
      t.time :deleted_at
      t.timestamps
    end
    
    add_index :media, :type
    add_index :media, :content_width
    add_index :media, :content_height
    add_index :media, :author_username
    add_index :media, :deleted_at
    
  end
end
