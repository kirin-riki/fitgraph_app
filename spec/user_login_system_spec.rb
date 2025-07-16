require 'rails_helper'

RSpec.describe 'ユーザーログイン', type: :system do
  before do
    driven_by(:rack_test)
    User.create!(name: 'テストユーザー', email: 'login_test@example.com', password: 'password123', password_confirmation: 'password123')
  end

  it '正しい情報でログインできる' do
    visit new_user_session_path
    fill_in 'メールアドレス', with: 'login_test@example.com'
    fill_in 'パスワード', with: 'password123'
    click_button 'ログイン'

    expect(page).to have_content('ログインしました').or have_content('ようこそ').or have_content('マイページ')
  end

  it '誤ったパスワードではログインできずエラーが表示される' do
    visit new_user_session_path
    fill_in 'メールアドレス', with: 'login_test@example.com'
    fill_in 'パスワード', with: 'wrongpassword'
    click_button 'ログイン'

    expect(page).to have_content('メールアドレスまたはパスワードが正しくありません。')
  end

  it '未入力の場合はバリデーションエラーが表示される' do
    visit new_user_session_path
    fill_in 'メールアドレス', with: ''
    fill_in 'パスワード', with: ''
    click_button 'ログイン'

    expect(page).to have_content('メールアドレスまたはパスワードが正しくありません。')
  end
end 