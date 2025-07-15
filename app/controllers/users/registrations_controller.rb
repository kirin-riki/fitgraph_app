class Users::RegistrationsController < Devise::RegistrationsController
  def build_resource(hash = {})
    hash[:uid] = User.create_unique_string
    super
  end

  def update_resource(resource, params)
    return super if params["password"].present?

    resource.update_without_password(params.except("current_password"))
  end

  def destroy
    # 例：関連ジョブのキャンセル、LINE 連携解除など
    current_user.cancel_scheduled_jobs
    current_user.unlink_line_if_needed
    super   # ← ここで User.destroy が呼ばれる
  end
end
