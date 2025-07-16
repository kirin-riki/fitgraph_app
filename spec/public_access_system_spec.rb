require 'rails_helper'

RSpec.describe '未ログイン状態でのアクセス', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'トップページにアクセスできる' do
    visit unauthenticated_root_path
    expect(page).to have_content('Fitgraph')
  end

  it '使い方ページにアクセスできる' do
    visit how_to_path
    expect(page).to have_content('使い方')
  end

  it '利用規約ページにアクセスできる' do
    visit terms_path
    expect(page).to have_content('利用規約')
  end

  it 'プライバシーポリシーページにアクセスできる' do
    visit privacy_path
    expect(page).to have_content('プライバシーポリシー')
  end

  it '新規登録ページにアクセスできる' do
    visit new_user_registration_path
    expect(page).to have_content('新規登録')
  end

  it 'パスワードリセットページにアクセスできる' do
    visit new_user_password_path
    expect(page).to have_content('パスワード再設定').or have_content('パスワードをお忘れの方')
  end

  it 'ログインページにアクセスできる' do
    visit new_user_session_path
    expect(page).to have_content('ログイン')
  end
end 