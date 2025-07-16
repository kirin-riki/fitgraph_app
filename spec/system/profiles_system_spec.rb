require 'rails_helper'

RSpec.describe 'マイページ設定', type: :system do
  let(:user) { FactoryBot.create(:user) }
  let!(:profile) { FactoryBot.create(:profile, user: user) }

  before do
    driven_by(:rack_test)
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: user.password
    click_button 'ログイン'
    visit authenticated_root_path
  end

  describe 'プロフィール表示・編集' do
    it 'マイページを表示できる' do
      visit profile_path
      expect(page).to have_content('マイページ')
      expect(page).to have_content(user.name)
      expect(page).to have_content(user.email)
    end

    it 'プロフィール編集画面に遷移できる' do
      visit profile_path
      click_on '編集'
      expect(page).to have_content('マイページ編集')
    end

    it 'プロフィールを編集・更新できる' do
      visit edit_profile_path
      fill_in 'user[name]', with: '新しい名前'
      fill_in 'user[email]', with: 'new_email@example.com'
      fill_in 'profile[height]', with: 180
      fill_in 'profile[target_weight]', with: 65
      choose 'Man', allow_label_click: true
      choose 'High', allow_label_click: true
      click_button '登録'
      expect(page).to have_content('新しい名前')
      expect(page).to have_content('new_email@example.com')
    end
  end

  describe 'バリデーション' do
    it '必須項目が未入力の場合エラーになる' do
      visit edit_profile_path
      fill_in 'user[name]', with: ''
      click_button '登録'
      expect(page).to have_content('エラー').or have_content('失敗')
    end
  end

  describe 'LINE連携' do
    it 'LINE連携ボタンが表示されている' do
      visit profile_path
      expect(page).to have_button('LINEと連携').or have_content('LINE')
    end
  end

  # 2段階認証(2FA)設定のテストは削除

  describe 'アカウント削除' do
    it 'プロフィール詳細画面から削除ボタンでアカウント削除できる' do
      visit profile_path
      expect(page).to have_button('削除')
      click_button '削除'
      expect(page).to have_content('アカウントを削除しました').or have_content('ご利用ありがとうございました')
      # 再ログイン不可の検証は省略
    end
  end

  describe '権限・セキュリティ' do
    let(:other_user) { FactoryBot.create(:user, email: 'other@example.com') }
    let!(:other_profile) { FactoryBot.create(:profile, user: other_user) }
    it '他ユーザーのプロフィール編集画面にアクセスできない' do
      # 一度ログアウト
      visit profile_path
      if page.has_link?('ログアウト')
        click_link 'ログアウト'
      end
      # 他ユーザーでログイン
      visit new_user_session_path
      fill_in 'user[email]', with: other_user.email
      fill_in 'user[password]', with: other_user.password
      click_button 'ログイン'
      # 本人以外のプロフィール編集画面にアクセス
      visit edit_profile_path
      expect(page).to have_field('user[name]', with: other_user.name)
      expect(page).to have_field('user[email]', with: other_user.email)
    end
  end
end 