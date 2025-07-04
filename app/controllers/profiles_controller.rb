class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: %i[show edit update]

  def show; end

  def edit; end

  def update
    if params[:line_friend]
      current_user.update(line_friend: true)
      redirect_to profile_path, notice: "LINE友だち追加を確認しました"
    else
      user_updated = @user.update(user_params)
      profile_updated = @profile.update(profile_params)

      if user_updated && profile_updated
        redirect_to profile_path, success: "プロフィールを更新しました。"
      else
        flash.now[:danger] = "プロフィールの更新に失敗しました"
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private

  def set_profile
    @user    = current_user
    @profile = current_user.profile || current_user.build_profile
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def profile_params
    params.require(:profile).permit(:height, :target_weight, :gender, :training_intensity)
  end
end
