class RemoveUserIdFromRecommendedVideos < ActiveRecord::Migration[7.2]
  def change
    remove_reference :recommended_videos, :user, index: true
  end
end
