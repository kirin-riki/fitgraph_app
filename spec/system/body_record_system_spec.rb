require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe '身体情報入力・編集', type: :system do
  let(:user) { User.create!(name: '入力ユーザー', email: 'body_test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    driven_by(:rack_test)
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password123'
    click_button 'ログイン'
    visit authenticated_root_path
  end

  it '新規で身体情報を入力・登録できる' do
    # 今日の日付を選択し、入力ボタンを押す
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: 65.5
    fill_in '体脂肪率', with: 18.2
    click_button '登録する'
    expect(page).to have_content('身体情報を登録しました').or have_content('身体情報を更新しました')
    # カレンダーに戻り、今日が記録済み色になっている
    expect(page).to have_selector('a.border-purple-500.text-purple-700', text: Date.current.day.to_s)
  end

  it '既存の身体情報を編集できる' do
    # 事前にレコード作成
    user.body_records.create!(recorded_at: Date.current, weight: 60, body_fat: 20)
    visit authenticated_root_path
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: 62.3
    fill_in '体脂肪率', with: 19.1
    click_button '更新する'
    expect(page).to have_content('身体情報を更新しました')
    # 値が更新されていることを確認
    within('.simple-calendar') do
      expect(page).to have_selector('a.border-purple-500.text-purple-700', text: Date.current.day.to_s)
    end
  end

  it '体重・体脂肪率が未入力でも登録できる' do
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: ''
    fill_in '体脂肪率', with: ''
    click_button '登録する'
    expect(page).to have_content('身体情報を登録しました').or have_content('身体情報を更新しました')
  end

  it '体重が300を超えるとバリデーションエラーになる' do
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: 301
    fill_in '体脂肪率', with: 20
    click_button '登録する'
    expect(page).to have_content('体重は300以下で入力してください')
  end

  it '体脂肪率が100を超えるとバリデーションエラーになる' do
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: 60
    fill_in '体脂肪率', with: 101
    click_button '登録する'
    expect(page).to have_content('体脂肪率は100以下で入力してください')
  end

  it '体重・体脂肪率に負の値を入力した場合はバリデーションエラーになる' do
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: -1
    fill_in '体脂肪率', with: -5
    click_button '登録する'
    expect(page).to have_content('体重は0以上の値にしてください').or have_content('体脂肪率は0以上の値にしてください')
  end

  it '体重・体脂肪率に数値以外を入力した場合はバリデーションエラーになる' do
    within('.simple-calendar') do
      all('a', text: Date.current.day.to_s).first.click
    end
    click_link '＋ 身体情報を入力・編集'
    fill_in '体重', with: 'abc'
    fill_in '体脂肪率', with: 'xyz'
    click_button '登録する'
    expect(page).to have_content('体重は数値で入力してください').or have_content('体脂肪率は数値で入力してください')
  end
end
