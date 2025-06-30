class ChangeTargetWeightToIntegerInProfiles < ActiveRecord::Migration[7.2]
  def change
    change_column :profiles, :target_weight, :integer, using: 'target_weight::integer'
  end
end
