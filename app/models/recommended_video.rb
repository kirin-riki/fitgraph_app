class RecommendedVideo < ApplicationRecord
  # belongs_to :user を削除 - 条件ベースのキャッシュにする

  validates :video_id, presence: true, uniqueness: { scope: :condition_key }
  validates :condition_key, presence: true

  # 条件別のスコープ
  scope :for_conditions, ->(gender, intensity) { where(condition_key: condition_key(gender, intensity)) }
  scope :recent, ->(months = 3) { where("fetched_at >= ?", months.months.ago) }

  # 条件キーの生成
  def self.condition_key(gender, intensity)
    "#{gender}_#{intensity}"
  end
end
