# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe '未ログイン状態でのアクセス', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'トップページにアクセスできる' do
    # ...
  end

  it '使い方ページにアクセスできる' do
    # ...
  end

  it '利用規約ページにアクセスできる' do
    # ...
  end

  it 'プライバシーポリシーページにアクセスできる' do
    # ...
  end

  it '新規登録ページにアクセスできる' do
    # ...
  end

  it 'パスワードリセットページにアクセスできる' do
    # ...
  end

  it 'ログインページにアクセスできる' do
    # ...
  end
end
