class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)
    if resource.otp_required_for_login
      # 2FA有効ならセッションにフラグをセットして2FA画面へ
      session[:user_id] = resource.id
      redirect_to new_user_two_factor_authentication_path
    else
      # 2FA無効なら通常通り
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  def destroy
    session.delete(:two_factor_authenticated)
    session.delete(:just_enabled_2fa)
    super
  end
end
