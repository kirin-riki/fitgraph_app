class Profile < ApplicationRecord
  belongs_to :user

  enum gender:             { male: 0, female: 1, other: 2 }
  enum training_intensity: { low: 0, medium: 1, high: 2 }

  validates :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :target_weight, numericality: { greater_than: 0 }, allow_nil: true
end
