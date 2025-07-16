require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe '記録（Progress/グラフ）画面', type: :system do
  let(:user) { User.create!(name: '記録ユーザー', email: 'progress_test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    driven_by(:rack_test)
    # 3件の記録を作成
    user.body_records.create!(recorded_at: 3.days.ago, weight: 60, body_fat: 20)
    user.body_records.create!(recorded_at: 2.days.ago, weight: 61, body_fat: 19)
    user.body_records.create!(recorded_at: 1.day.ago, weight: 62, body_fat: 18)
    # 画像付き記録
    user.body_records.create!(recorded_at: Date.current, weight: 63, body_fat: 17, photo: fixture_file_upload(Rails.root.join('spec/fixtures/test.jpg'), 'image/jpeg'))
    # 目標体重
    user.create_profile!(target_weight: 59)
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password123'
    click_button 'ログイン'
    visit progress_path
  end

  it 'グラフが表示される', skip: '一時的にskip' do
    expect(page).to have_selector('canvas#weightChart')
  end

  it '記録データがグラフに反映されている', skip: '一時的にskip' do
    expect(page).to have_selector('#first-weight', text: '60.00')
    expect(page).to have_selector('#last-weight', text: '63.00')
    expect(page).to have_selector('#first-fat', text: '20.00')
    expect(page).to have_selector('#last-fat', text: '17.00')
  end

  it '期間タブを切り替えるとグラフの表示範囲が変わる', skip: '一時的にskip' do
    within('#graph-view') do
      all('button', text: '1ヶ月').first.click
      expect(page).to have_selector('canvas#weightChart')
      all('button', text: '1週間').first.click
      expect(page).to have_selector('canvas#weightChart')
      all('button', text: '3ヶ月').first.click
      expect(page).to have_selector('canvas#weightChart')
    end
  end

  it '目標体重がグラフ上に表示される', skip: '一時的にskip' do
    expect(page).to have_content('目標まであと').or have_content('目標体重').or have_content('59')
  end

  it '統計情報が表示される', skip: '一時的にskip' do
    expect(page).to have_selector('#stats-table')
    expect(page).to have_selector('#first-weight')
    expect(page).to have_selector('#last-weight')
    expect(page).to have_selector('#first-fat')
    expect(page).to have_selector('#last-fat')
  end

  it '写真タブをクリックすると写真ビューが表示される', skip: '一時的にskip' do
    click_button '写真'
    expect(page).to have_selector('[data-controller="photo-switcher"]')
    expect(page).to have_selector('img')
  end

  it '写真の期間タブをクリックして画像が切り替わる', skip: '一時的にskip' do
    click_button '写真'
    within('#photo-view') do
      all('button', text: '1ヶ月').first.click
      expect(page).to have_selector('img')
      all('button', text: '3ヶ月').first.click
      expect(page).to have_selector('img')
    end
  end

  it '写真ビューでレイヤー/比較タブの切り替えができる', skip: '一時的にskip' do
    click_button '写真'
    click_button '比較'
    expect(page).to have_selector('#compare-view', visible: true)
    click_button 'レイヤー'
    expect(page).to have_selector('#layer-view', visible: true)
  end

  it '写真ビューでスライダーをスライドすると画像が切り替わる', skip: '一時的にskip' do
    click_button '写真'
    if page.has_selector?('input[type="range"]', visible: true)
      slider = find('input[type="range"]', visible: true)
      slider.set(2)
      expect(page).to have_selector('img')
    end
  end

  it '記録が1件もない場合はグラフや統計が「データなし」や0.00kgになる', skip: '一時的にskip' do
    user.body_records.destroy_all
    visit progress_path
    expect(page).to have_content('データなし').or have_content('記録がありません').or have_content('0.00 kg')
  end

  it '記録が1件だけの場合も正しく表示される' do
    user.body_records.destroy_all
    user.body_records.create!(recorded_at: Date.current, weight: 70, body_fat: 25)
    visit progress_path
    expect(page).to have_content('70')
    expect(page).to have_content('25')
  end

  it '目標体重を達成した場合は「目標達成！！！」が表示される' do
    user.body_records.where(recorded_at: Date.current).destroy_all
    user.body_records.create!(recorded_at: Date.current, weight: 58, body_fat: 15)
    visit progress_path
    expect(page).to have_content('目標達成')
  end
end
