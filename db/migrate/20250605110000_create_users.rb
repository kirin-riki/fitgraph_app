class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :line_user_id,    null: false
      t.string :name,            null: false
      t.string :email,           null: false

      t.timestamps
    end

    add_index :users, :line_user_id, unique: true
    add_index :users, :email,        unique: true
    validates :email, presence: true
  end
end
