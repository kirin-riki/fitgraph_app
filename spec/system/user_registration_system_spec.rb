# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe 'ユーザー登録', type: :system do
  before do
    driven_by(:rack_test)
  end

  it '正常に新規登録できる' do
    # ...
  end

  it 'バリデーションエラーが表示される' do
    # ...
  end
end
