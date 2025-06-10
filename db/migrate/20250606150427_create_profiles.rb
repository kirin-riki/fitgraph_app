class CreateProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.integer :height
      t.integer :gender,              null: false, default: 0  # enum :male, :female

      t.integer :training_intensity,  null: false, default: 0  # enum :low, :medium, :high
      t.decimal :target_weight,       precision: 5, scale: 2
      t.date    :start_date

      t.timestamps
    end
  end
end