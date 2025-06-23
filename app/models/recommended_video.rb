class RecommendedVideo < ApplicationRecord
  validates :video_id, presence: true, uniqueness: { scope: :condition_key }
  validates :condition_key, presence: true

  scope :for_conditions, ->(gender, intensity) { where(condition_key: condition_key(gender, intensity)) }
  scope :recent, ->(months = 3) { where("fetched_at >= ?", months.months.ago) }

  def self.condition_key(gender, intensity)
    "#{gender}_#{intensity}"
  end
end
