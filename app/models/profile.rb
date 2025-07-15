class Profile < ApplicationRecord
  belongs_to :user


  enum :gender, { man: 0, woman: 1, other: 2 }
  enum :training_intensity, { low: 0, medium: 1, high: 2 }

  validates :height, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :target_weight, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  def condition_key
    return nil if gender.nil? || training_intensity.nil?
    "#{gender}_#{training_intensity}"
  end
end
