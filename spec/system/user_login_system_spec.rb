# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe 'ユーザーログイン', type: :system do
  before do
    driven_by(:rack_test)
    User.create!(name: 'テストユーザー', email: 'login_test@example.com', password: 'password123', password_confirmation: 'password123')
  end

  it '正しい情報でログインできる' do
    # ...
  end

  it '誤ったパスワードではログインできずエラーが表示される' do
    # ...
  end

  it '未入力の場合はバリデーションエラーが表示される' do
    # ...
  end
end
