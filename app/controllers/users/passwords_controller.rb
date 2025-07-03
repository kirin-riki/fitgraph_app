class Users::PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    # メールアドレスが見つからない場合もエラーを出さずにログインページへ
    redirect_to new_user_session_path, notice: "パスワード再設定用のメールを送信しました。"
  end
end 