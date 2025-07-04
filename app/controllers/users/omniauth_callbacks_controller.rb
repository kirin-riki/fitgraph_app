class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    callback_for(:google)
  end

  def line
    auth = request.env['omniauth.auth']
    state = request.params['state']

    if state == 'link' && current_user
      current_user.update(
        uid: auth['uid'],
        line_user_id: auth['uid']
      )
      redirect_to profile_path, notice: 'LINE連携が完了しました'
    else
      @user = User.from_omniauth(auth)
      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: 'LINE') if is_navigational_format?
      else
        session['devise.line_data'] = auth.except(:extra)
        redirect_to new_user_registration_url
      end
    end
  end

  def callback_for(provider)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end

  def failure
    unauthenticated_root_path
  end
end
