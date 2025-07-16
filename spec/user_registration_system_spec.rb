require 'rails_helper'

RSpec.describe 'ユーザー登録', type: :system do
  before do
    driven_by(:rack_test)
  end

  it '正常に新規登録できる' do
    visit new_user_registration_path
    fill_in 'ユーザー名', with: 'テストユーザー'
    fill_in 'メールアドレス', with: 'test@example.com'
    fill_in 'パスワード', with: 'password123'
    fill_in 'パスワード（確認）', with: 'password123'
    click_button '新規登録'

    expect(page).to have_content('アカウント登録が完了しました').or have_content('ようこそ')
    expect(User.find_by(email: 'test@example.com')).to be_present
  end

  it 'バリデーションエラーが表示される' do
    visit new_user_registration_path
    fill_in 'ユーザー名', with: ''
    fill_in 'メールアドレス', with: 'test@example.com'
    fill_in 'パスワード', with: 'short'
    fill_in 'パスワード（確認）', with: 'mismatch'
    click_button '新規登録'

    expect(page).to have_content('ユーザー名を入力してください').or have_content('ユーザー名が入力されていません')
    expect(page).to have_content('パスワードは6文字以上で入力してください')
    expect(page).to have_content('パスワード確認とパスワードの入力が一致しません')
  end
end 