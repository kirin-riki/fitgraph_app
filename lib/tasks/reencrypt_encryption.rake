# lib/tasks/reencrypt_encryption.rake
namespace :ar_encryption do
  desc "Re-encrypt all ActiveRecord encrypted attributes with current keys"
  task reencrypt: :environment do
    # ApplicationRecord を基底に持つ全モデルを調べる
    ApplicationRecord.descendants.each do |model|
      # encrypted_attributes が定義されているモデルだけ処理
      next unless model.respond_to?(:encrypted_attributes) && model.encrypted_attributes.any?

      puts "Re-encrypting #{model.name}..."
      model.find_each(batch_size: 100) do |record|
        # 各 encrypted 属性を一度読み込んで再代入
        model.encrypted_attributes.each do |attr|
          val = record.send(attr)
          record.send("#{attr}=", val)
        end
        # バリデーションをスキップして保存（暗号化が走る）
        record.save!(validate: false)
      end
    end
    puts "Re-encryption complete."
  end
end
