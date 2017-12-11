class DailyOperatingHoursController < ApplicationController
  before_action :load_operatable

  respond_to :html, :js

  def new
    @date_flag = params[:date_flag]
    @date =  Date.strptime(params[:date_flag], "%Y-%m-%d")
    @available_times = current_provider.operating_hours.for_day_of_week(@date.wday).get_available_times(interval: (current_provider.driver_availability_interval_min || 30).minutes)
    @operating_hour = @operatable.daily_operating_hours.new(date: @date)
  end

  def add
    if @operatable
      @date =  Date.strptime(params[:date_flag], "%Y-%m-%d")
      @day_of_week = @date.wday
      if params[:is_all_day] == 'true'
        @is_all_day = true
      elsif params[:is_unavailable] == 'true'
        @is_unavailable = true
      end
      @has_error = DailyOperatingHoursProcessor.new(@operatable,{
        is_all_day: @is_all_day,
        is_unavailable: @is_unavailable,
        date: @date,
        start_time: params[:start_time],
        end_time: params[:end_time]
        }).process!

      if !@has_error && !@is_all_day && !@is_unavailable
        @time_ranges = []
        @operatable.daily_operating_hours.regular.for_date(@date).pluck(:start_time, :end_time).each do |t|
          @time_ranges << [(t[0] - t[0].at_beginning_of_day) / 3600.0, (t[1] - t[1].at_beginning_of_day) / 3600.0]
        end
      end
    end
  end

  def remove
    if @operatable
      @date =  Date.strptime(params[:date_flag], "%Y-%m-%d")
      @operatable.daily_operating_hours.for_date(@date).destroy_all
      @day_of_week = @date.wday
    end
  end

  private

  def load_operatable
    @operatable = DailyOperatingHour.new(operatable_id: params[:operatable_id], operatable_type: params[:operatable_type]).operatable
  end
end