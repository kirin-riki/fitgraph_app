class BodyRecordForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :recorded_at
  attribute :weight, :float
  attribute :body_fat, :float
  attribute :fat_mass, :float
  attribute :photo

  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }, allow_nil: true
  validates :body_fat, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :fat_mass, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def initialize(attributes = {})
    # recorded_at を DateParsingService でパース
    if attributes[:recorded_at].present?
      attributes[:recorded_at] = DateParsingService.parse_to_beginning_of_day(attributes[:recorded_at])
    end
    super(attributes)
  end

  # BodyRecord に保存するための属性ハッシュを返す
  # photo は別途処理するため除外
  def body_record_attributes
    {
      recorded_at: recorded_at,
      weight: weight,
      body_fat: body_fat,
      fat_mass: fat_mass
    }
  end

  # photo が添付されているかを判定
  def photo_attached?
    photo.present?
  end
end
