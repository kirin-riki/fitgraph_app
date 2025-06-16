class ProgressController < ApplicationController
  def index
    @records = BodyRecord.order(:recorded_at)

    @dates = @records.map { |r| r.recorded_at.strftime("%Y-%m-%d") }
    @weight_values = @records.map(&:weight)
    @fat_values = @records.map(&:body_fat)
  end
end
