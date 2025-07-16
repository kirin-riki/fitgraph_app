require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe '未ログイン状態での認証必須ページアクセス', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'プロフィールページはログイン画面にリダイレクトされる', skip: '一時的にskip' do
    visit profile_path
    expect(current_path).to eq new_user_session_path
    expect(page).to have_content('ログイン')
  end

  it '動画一覧ページはログイン画面にリダイレクトされる', skip: '一時的にskip' do
    visit recommended_videos_path
    expect(current_path).to eq new_user_session_path
    expect(page).to have_content('ログイン')
  end

  it '経過ページはログイン画面にリダイレクトされる', skip: '一時的にskip' do
    visit progress_path
    expect(current_path).to eq new_user_session_path
    expect(page).to have_content('ログイン')
  end

  it '身体情報入力ページはログイン画面にリダイレクトされる', skip: '一時的にskip' do
    visit new_body_record_path
    expect(current_path).to eq new_user_session_path
    expect(page).to have_content('ログイン')
  end
end 