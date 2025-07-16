class BodyRecordPhotoService
  def initialize(body_record)
    @body_record = body_record
  end

  def attach_processed_photo(photo_param)
    begin
      processed = ImageProcessing::MiniMagick
                    .source(photo_param.tempfile)
                    .resize_to_limit(600, 600)
                    .quality(60)
                    .call
      if processed.size > 1024 * 1024
        processed = ImageProcessing::MiniMagick
                      .source(processed)
                      .quality(50)
                      .call
      end
      @body_record.photo.attach(
        io: processed,
        filename: photo_param.original_filename,
        content_type: photo_param.content_type
      )
    rescue => e
      @body_record.photo.attach(photo_param)
    end
  end
end 