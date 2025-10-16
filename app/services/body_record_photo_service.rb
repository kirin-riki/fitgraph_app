class BodyRecordPhotoService
  def initialize(body_record)
    @body_record = body_record
  end

  def attach_processed_photo(photo_param)
    begin
      # メモリ使用量を制限するため、より小さなサイズにリサイズ
      processed = ImageProcessing::MiniMagick
                    .source(photo_param.tempfile)
                    .resize_to_limit(400, 400)  # 600x600から400x400に縮小
                    .quality(50)                # 品質を下げてファイルサイズを削減
                    .call
      
      # ファイルサイズチェックを厳格化
      if processed.size > 512 * 1024  # 1MBから512KBに制限
        processed = ImageProcessing::MiniMagick
                      .source(processed)
                      .quality(30)    # さらに品質を下げる
                      .call
      end
      
      @body_record.photo.attach(
        io: processed,
        filename: photo_param.original_filename,
        content_type: photo_param.content_type
      )
    rescue => e
      Rails.logger.error "Image processing failed: #{e.message}"
      # フォールバック: 元の画像をそのままアップロード
      @body_record.photo.attach(photo_param)
    end
  end
end
