class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[show edit update]

  def show; end

  def edit; end

  def update
    if @user.update(user_params) && @profile.update(profile_params)
      redirect_to profile_path
    else
      render "edit"
    end
  end

  private

  def set_profile
    @user    = current_user
    @profile = current_user.profile ||
               current_user.build_profile
  end


  def user_params
    params.require(:user).permit(:name, :email)
  end

  def profile_params
    params.require(:profile).permit(:height, :target_weight, :gender, :training_intensity)
  end
end
