class BodyRecord < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }, allow_nil: true
  validates :body_fat, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  
  # 画像ファイルのバリデーション
  validates :photo, content_type: { in: %w[image/jpeg image/jpg image/png image/gif],
                                    message: 'はJPEG、PNG、GIF形式のみ対応しています' },
                    size: { less_than: 5.megabytes, message: 'は5MB以下にしてください' }
end
