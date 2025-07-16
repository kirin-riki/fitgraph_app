FactoryBot.define do
  factory :body_record do
    association :user
    weight { 60.0 }
    body_fat { 20.0 }
    recorded_at { Time.current }
  end
end
