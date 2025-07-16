FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    email { "user_#{SecureRandom.hex(4)}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    uid { SecureRandom.hex(8) }
    provider { "google" }
  end
end 