class BodyRecord < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }, allow_blank: true
  validates :body_fat, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true

  # user_idの変更を禁止（直接登録・改ざんを防ぐ）
  before_update :prevent_user_id_change

  private

  def prevent_user_id_change
    if user_id_changed? && persisted?
      errors.add(:user_id, "は変更できません")
      restore_attribute(:user_id)
      throw(:abort)
    end
  end
end
