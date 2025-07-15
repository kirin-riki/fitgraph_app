class CreateBodyRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :body_records do |t|
      t.references :user,        null: false, foreign_key: true      # user_id
      t.datetime   :recorded_at, null: false                         # 測定日時

      t.decimal :weight,    precision: 5, scale: 2
      t.decimal :body_fat,  precision: 4, scale: 1
      t.decimal :fat_mass,  precision: 5, scale: 2

      t.timestamps
    end

    add_index :body_records, %i[user_id recorded_at], unique: true
  end
end
