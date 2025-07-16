require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe 'カレンダートップページ', type: :system do
  let(:user) { User.create!(name: 'カレンダーユーザー', email: 'calendar_test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    driven_by(:rack_test)
    # 1日と15日に記録がある状態を作る
    user.body_records.create!(recorded_at: Date.current.beginning_of_month, weight: 60, body_fat: 20)
    user.body_records.create!(recorded_at: Date.current.beginning_of_month + 14, weight: 61, body_fat: 19)
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password123'
    click_button 'ログイン'
    visit authenticated_root_path
  end

  it 'カレンダーに今月の日付が正しく表示されている', skip: '一時的にskip' do
    # 1日と15日がリンクとして存在
    expect(page).to have_link('1')
    expect(page).to have_link('15')
    # 月名と年が表示されている
    month_name = I18n.t('date.month_names')[Date.current.month]
    expect(page).to have_content(month_name)
    expect(page).to have_content(Date.current.year.to_s)
  end

  it '記録がある日は色や枠線がついている', skip: '一時的にskip' do
    # 1日と15日のセルに特定のクラスが付与されているか
    expect(page).to have_selector("a.border-purple-500.text-purple-700", text: '1')
    expect(page).to have_selector("a.border-purple-500.text-purple-700", text: '15')
    # 記録がない日はグレー系
    expect(page).to have_selector("a.text-gray-400", text: '2')
  end

  it '翌月・先月に移動できる' do
    # 翌月へ
    click_link 'Next'
    next_month = Date.current.next_month
    expect(page).to have_content(I18n.t('date.month_names')[next_month.month])
    expect(page).to have_content(next_month.year.to_s)
    # 先月へ
    click_link 'Previous'
    expect(page).to have_content(I18n.t('date.month_names')[Date.current.month])
    expect(page).to have_content(Date.current.year.to_s)
  end

  it '今日の日付がハイライトされている' do
    today = Date.current.day.to_s
    expect(page).to have_selector("a.bg-purple-200.font-bold.text-purple-700", text: today)
  end

  it '選択中の日付は濃い紫で表示される' do
    # 初期表示は今日が選択中
    today = Date.current.day.to_s
    expect(page).to have_selector("a.bg-purple-700.text-white", text: today)
  end

  it '記録がある日をクリックすると編集画面に遷移する' do
    within('.simple-calendar') do
      all('a', text: '1').find { |a| a[:class].include?('border-purple-500') }.click
    end
    expect(page).to have_link('＋ 身体情報を入力・編集')
    click_link '＋ 身体情報を入力・編集'
    expect(page).to have_selector('form')
    expect(page).to have_field('body_record[weight]', with: "60.0")
  end

  it '記録がない日をクリックすると新規入力画面に遷移する' do
    within('.simple-calendar') do
      all('a', text: '2').find { |a| a[:class].include?('text-gray-400') }.click
    end
    expect(page).to have_link('＋ 身体情報を入力・編集')
    click_link '＋ 身体情報を入力・編集'
    expect(page).to have_selector('form')
    expect(page).to have_field('body_record[weight]')
    expect(find_field('body_record[weight]').value).to be_blank
  end
end
