# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe '未ログイン状態でのアクセス', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'トップページにアクセスできる', skip: '一時的にskip' do
    # ...
  end

  it '使い方ページにアクセスできる', skip: '一時的にskip' do
    # ...
  end

  it '利用規約ページにアクセスできる', skip: '一時的にskip' do
    # ...
  end

  it 'プライバシーポリシーページにアクセスできる', skip: '一時的にskip' do
    # ...
  end

  it '新規登録ページにアクセスできる', skip: '一時的にskip' do
    # ...
  end

  it 'パスワードリセットページにアクセスできる', skip: '一時的にskip' do
    # ...
  end

  it 'ログインページにアクセスできる', skip: '一時的にskip' do
    # ...
  end
end 