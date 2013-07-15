class MediaSettings < ActiveRecord::Migration
  def change
    create_table :media_settings do |t|
      t.string :source
      t.string :key
      t.string :value
      t.timestamps
    end
    add_index :media_settings, [:source, :key]
  end
end
