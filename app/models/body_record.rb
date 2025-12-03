class BodyRecord < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }, allow_blank: true
  validates :body_fat, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true
end
