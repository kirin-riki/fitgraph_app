class AllowNullLineUserIdOnUsers < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :line_user_id, true
  end
end
