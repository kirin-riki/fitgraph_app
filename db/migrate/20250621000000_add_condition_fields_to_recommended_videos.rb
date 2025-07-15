class AddConditionFieldsToRecommendedVideos < ActiveRecord::Migration[7.2]
  def change
    add_column :recommended_videos, :condition_key, :string

    # 条件別のインデックスを追加
    add_index :recommended_videos, [ :user_id, :condition_key ]
    add_index :recommended_videos, [ :user_id, :condition_key, :fetched_at ]

    # 既存データの移行（一時的にreversibleを無効化）
    reversible do |dir|
      dir.up do
        # 既存データにデフォルトのcondition_keyを設定
        # 注意: これは仮の設定です。実際のプロフィール条件に合わせる必要があります
        execute "UPDATE recommended_videos SET condition_key = 'man_low' WHERE condition_key IS NULL"
      end
    end
  end
end
