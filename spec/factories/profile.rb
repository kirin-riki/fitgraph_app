FactoryBot.define do
  factory :profile do
    association :user
    height { 170 }
    gender { :man }
    training_intensity { :low }
    target_weight { 60 }
    start_date { Date.today }
  end
end
