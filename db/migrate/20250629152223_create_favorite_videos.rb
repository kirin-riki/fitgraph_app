class CreateFavoriteVideos < ActiveRecord::Migration[7.2]
  def change
    create_table :favorite_videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :youtube_url, null: false
      t.string :title, null: false
      t.string :thumbnail_url, null: false
      t.timestamps
    end
  end
end
