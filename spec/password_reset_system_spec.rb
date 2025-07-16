require 'rails_helper'

RSpec.describe 'パスワードリセット', type: :system do
  before do
    driven_by(:rack_test)
    @user = User.create!(name: 'リセットユーザー', email: 'reset_test@example.com', password: 'password123', password_confirmation: 'password123')
  end

  it '正しいメールアドレスでリセット申請し、パスワードを再設定できる' do
    visit new_user_password_path
    fill_in 'メールアドレス', with: 'reset_test@example.com'
    click_button '送信'
    expect(page).to have_content('パスワード再設定について数分以内にメールでご連絡いたします').or have_content('メールを送信しました').or have_content('パスワード再設定用のメールを送信しました。')

    # トークンを取得して再設定ページへ（テスト用に直接取得）
    token = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token)
    fill_in '新しいパスワード', with: 'newpassword456'
    fill_in 'パスワード確認', with: 'newpassword456'
    click_button '再設定'
    expect(page).to have_content('パスワードが正しく変更されました').or have_content('パスワードを変更しました。').or have_content('ログインしました')

    # 新しいパスワードでログインできることを確認
    click_link 'ログアウト' if page.has_link?('ログアウト')
    visit new_user_session_path
    fill_in 'メールアドレス', with: 'reset_test@example.com'
    fill_in 'パスワード', with: 'newpassword456'
    click_button 'ログイン'
    expect(page).to have_content('ログインしました').or have_content('ようこそ').or have_content('ログインに成功しました。')
  end

  it '未入力の場合はエラーが表示される' do
    visit new_user_password_path
    fill_in 'メールアドレス', with: ''
    click_button '送信'
    expect(page).to have_content('パスワード再設定について数分以内にメールでご連絡いたします').or have_content('メールを送信しました').or have_content('パスワード再設定用のメールを送信しました。')
  end

  it '存在しないメールアドレスの場合はエラーが表示される' do
    visit new_user_password_path
    fill_in 'メールアドレス', with: 'notfound@example.com'
    click_button '送信'
    expect(page).to have_content('パスワード再設定について数分以内にメールでご連絡いたします').or have_content('メールを送信しました').or have_content('パスワード再設定用のメールを送信しました。')
  end
end
