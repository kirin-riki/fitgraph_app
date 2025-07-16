class ProgressController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = params[:period] || "3m"
    data = ProgressDataService.new(current_user, @period).call

    @graph_records = data[:graph_records]
    @dates = data[:dates]
    @weight_values = data[:weight_values]
    @fat_values = data[:fat_values]
    @all_graph_records = data[:all_graph_records]
    @target_weight = data[:target_weight]

    first_record = data[:first_record]
    last_record  = data[:last_record]
    @first_weight = first_record&.weight || 0
    @last_weight  = last_record&.weight  || 0
    @first_fat    = first_record&.body_fat || 0
    @last_fat     = last_record&.body_fat  || 0
    @first_fat_mass = (first_record && first_record.weight && first_record.body_fat) ? (first_record.weight * first_record.body_fat / 100.0).round(2) : 0
    @last_fat_mass  = (last_record && last_record.weight && last_record.body_fat) ? (last_record.weight * last_record.body_fat / 100.0).round(2) : 0

    if @target_weight && @last_weight && @last_weight > 0
      if @last_weight <= @target_weight
        @weight_to_goal = 0
        @goal_achieved = true
      else
        @weight_to_goal = (@last_weight - @target_weight).round(2)
        @goal_achieved = false
      end
    else
      @weight_to_goal = 0
      @goal_achieved = false
    end

    @body_records_with_photo = data[:body_records_with_photo]
    @photos = @body_records_with_photo.map(&:photo)
    @all_photos = data[:all_photos]
  end
end
