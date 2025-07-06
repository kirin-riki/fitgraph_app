namespace :body_records do
  desc "全body_recordのrecorded_atを日付のみ（00:00:00）に揃える"
  task fix_dates: :environment do
    puts "--- Fixing body_records.recorded_at to 00:00:00 for all records..."
    BodyRecord.find_each do |rec|
      fixed = rec.recorded_at.to_date.beginning_of_day
      if rec.recorded_at != fixed
        rec.update_column(:recorded_at, fixed)
        puts "Fixed id=#{rec.id}: #{rec.recorded_at} => #{fixed}"
      end
    end
    puts "--- Done."
  end
end 