class FavoriteVideo < ApplicationRecord
  belongs_to :user

  validates :youtube_url, presence: true, uniqueness: { scope: :user_id }
  validates :title, presence: true, allow_blank: true
  validates :thumbnail_url, presence: true, allow_blank: true
  validates :channel_title, presence: true, allow_blank: true
  validate :favorite_videos_limit, on: :create

  private

  def favorite_videos_limit
    if user && user.favorite_videos.count >= 5
      errors.add(:base, "お気に入り動画は最大5件までです")
    end
  end
end
