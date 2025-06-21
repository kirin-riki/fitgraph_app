# db/migrate/20250621_create_recommended_videos.rb
class CreateRecommendedVideos < ActiveRecord::Migration[7.2]
  def change
    create_table :recommended_videos do |t|
      t.references :user,        null: false, foreign_key: true, index: true
      t.string     :video_id,    null: false
      t.string     :title,       null: false
      t.string     :thumbnail_url
      t.string     :channel_title
      t.integer    :view_count
      t.datetime   :fetched_at,  null: false

      t.timestamps
    end

    # API 取得日時と動画IDで検索しやすく、かつ同じ動画の重複登録を防止
    add_index :recommended_videos, :fetched_at
    add_index :recommended_videos, :video_id
    add_index :recommended_videos, [:user_id, :video_id], unique: true
  end
end
