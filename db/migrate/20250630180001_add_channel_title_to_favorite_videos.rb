class AddChannelTitleToFavoriteVideos < ActiveRecord::Migration[7.2]
  def change
    add_column :favorite_videos, :channel_title, :string
  end
end
