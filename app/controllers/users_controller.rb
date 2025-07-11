class UsersController < ApplicationController
  # befor_actionと一緒に使う
  before_action :authenticate_user!

  def index
    @user = User.find(current_user.id)
    favorites = Favorite.where(user_id: current_user.id).pluck(:institution_id)
    @favorites_list = Institution.find(favorites)
  end

  def edit
    @user = User.find(current_user.id)
  end

  def update
    @user = User.find(current_user.id)
    if @user.update(user_params)
      redirect_to edit_user_path(current_user), success: "登録情報を更新しました"
    else
      flash.now[:danger] = "登録情報の更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :email)
  end
end
