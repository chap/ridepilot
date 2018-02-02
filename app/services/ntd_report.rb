# NTD Report
# Modify an existing blank template

class NtdReport

  TEMPLATE_PATH = "#{Rails.root}/public/ntd_template.xlsx"
  
  attr_reader :workbook

  def initialize(provider, year, month)
    @provider = provider
    @year = year
    @month = month
    @start_date = Date.new(year, 1, 1)
    @end_date = Date.new(year, month, 1).at_end_of_month + 1.day
  end

  def export!
    @workbook = RubyXL::Parser.parse(TEMPLATE_PATH)
    @worksheet = @workbook[0] #first worksheet

    get_base_data

    process_periods_of_service
    process_year_month_headers
    process_operations
    process_miles_and_hours
    
    @workbook.calc_pr.full_calc_on_load = true
    @workbook
  end

  def get_base_data
    @runs = Run.complete.for_provider(@provider.try(:id)).for_date_range(@start_date, @end_date)
    @weekday_runs = @runs.where("extract(dow from date) in (?)", (1..5).to_a)
    @sat_runs = @runs.where("extract(dow from date) = ?", 6)
    @sun_runs = @runs.where("extract(dow from date) = ?", 0)

    @trips = Trip.for_provider(@provider.try(:id)).completed.joins(:run, :funding_source)
      .where("runs.complete = ?", true).for_date_range(@start_date, @end_date)
      .where(funding_sources: {ntd_reportable: true})
    @weekday_trips = @trips.where("extract(dow from pickup_time) in (?)", (1..5).to_a)
    @sat_trips = @trips.where("extract(dow from pickup_time) = ?", 6)
    @sun_trips = @trips.where("extract(dow from pickup_time) = ?", 0)
  end

  def process_periods_of_service
    @weekday_earliest_runs = @weekday_runs.where.not(scheduled_start_time_string: nil).group(:date).minimum(:scheduled_start_time_string)
    @worksheet[1][3].change_contents (get_average_time(@weekday_earliest_runs))
    @sat_earliest_runs = @sat_runs.where.not(scheduled_start_time_string: nil).group(:date).minimum(:scheduled_start_time_string)
    @worksheet[1][4].change_contents (get_average_time(@sat_earliest_runs))
    @sun_earliest_runs = @sun_runs.where.not(scheduled_start_time_string: nil).group(:date).minimum(:scheduled_start_time_string)
    @worksheet[1][5].change_contents (get_average_time(@sun_earliest_runs))

    @weekday_latest_runs = @weekday_runs.where.not(scheduled_end_time_string: nil).group(:date).maximum(:scheduled_end_time_string)
    @worksheet[2][3].change_contents (get_average_time(@weekday_latest_runs))
    @sat_latest_runs = @sat_runs.where.not(scheduled_end_time_string: nil).group(:date).maximum(:scheduled_end_time_string)
    @worksheet[2][4].change_contents (get_average_time(@sat_latest_runs))
    @sun_latest_runs = @sun_runs.where.not(scheduled_end_time_string: nil).group(:date).maximum(:scheduled_end_time_string)
    @worksheet[2][5].change_contents (get_average_time(@sun_latest_runs))
  end

  def process_year_month_headers
    # update row 4 with reporting year and month names
    @worksheet[4][3].change_contents @year

    (1..12).each do |m|
      @worksheet[4][m + 4].change_contents Date.new(@year, m, 1)
    end
    
  end

  def process_operations
    @num_max_operated_vehicles = @trips.group("extract(month from runs.date)").count("distinct(runs.vehicle_id)")

    @num_unlinked_passenger_weekday_trips = sum_monthly_trip_size @weekday_trips
    @num_unlinked_passenger_sat_trips = sum_monthly_trip_size @sat_trips
    @num_unlinked_passenger_sun_trips = sum_monthly_trip_size @sun_trips

    @days_operated_weekday = count_monthly_days_operated @weekday_trips
    @days_operated_sat = count_monthly_days_operated @sat_trips
    @days_operated_sun = count_monthly_days_operated @sun_trips

    (1..12).each do |m|
      # Vehicles operated in maximum service
      max_vehicles = @num_max_operated_vehicles[m.to_f]
      @worksheet[6][m + 4].change_value(max_vehicles) unless max_vehicles.nil?

      # Vehicles available in maximum service
      monthly_tracking = VehicleMonthlyTracking.where(provider_id: @provider.try(:id), year: @year, month: m).first
      @worksheet[7][m + 4].change_value(monthly_tracking.max_available_count) unless monthly_tracking.nil?

      # Unlinked passenger trips
      weekday_trip_size = @num_unlinked_passenger_weekday_trips[m.to_f]
      @worksheet[10][m + 4].change_value(weekday_trip_size) unless weekday_trip_size.nil?
      sat_trip_size = @num_unlinked_passenger_sat_trips[m.to_f]
      @worksheet[11][m + 4].change_value(sat_trip_size) unless sat_trip_size.nil?
      sun_trip_size = @num_unlinked_passenger_sun_trips[m.to_f]
      @worksheet[12][m + 4].change_value(sun_trip_size) unless sun_trip_size.nil?

      # # of days operated
      weekday_days = @days_operated_weekday[m.to_f]
      @worksheet[16][m + 4].change_value(weekday_days) unless weekday_days.nil?
      sat_days = @days_operated_sat[m.to_f]
      @worksheet[17][m + 4].change_value(sat_days) unless sat_days.nil?
      sun_days = @days_operated_sun[m.to_f]
      @worksheet[18][m + 4].change_value(sun_days) unless sun_days.nil?
    end
  end

  def process_miles_and_hours
    @weekday_stats = monthly_miles_hours @weekday_trips
    @sat_stats = monthly_miles_hours @sat_trips
    @sun_stats = monthly_miles_hours @sun_trips

    @total_miles_weekday = @weekday_stats[:total_miles]
    @total_miles_sat = @sat_stats[:total_miles]
    @total_miles_sun = @sun_stats[:total_miles]

    @revenue_miles_weekday = @weekday_stats[:revenue_miles]
    @revenue_miles_sat = @sat_stats[:revenue_miles]
    @revenue_miles_sun = @sun_stats[:revenue_miles]

    @passenger_miles_weekday = @weekday_stats[:passenger_miles]
    @passenger_miles_sat = @sat_stats[:passenger_miles]
    @passenger_miles_sun = @sun_stats[:passenger_miles]

    @total_hours_weekday = @weekday_stats[:total_hours]
    @total_hours_sat = @sat_stats[:total_hours]
    @total_hours_sun = @sun_stats[:total_hours]

    @total_revenue_hours_weekday = @weekday_stats[:total_revenue_hours]
    @total_revenue_hours_sat = @sat_stats[:total_revenue_hours]
    @total_revenue_hours_sun = @sun_stats[:total_revenue_hours]

    (1..12).each do |m|
      # Total Actual Miles
      total_miles_weekday = @total_miles_weekday[m.to_f]
      @worksheet[23][m + 4].change_value(total_miles_weekday) unless total_miles_weekday.nil?
      total_miles_sat = @total_miles_sat[m.to_f]
      @worksheet[24][m + 4].change_value(total_miles_sat) unless total_miles_sat.nil?
      total_miles_sun = @total_miles_sun[m.to_f]
      @worksheet[25][m + 4].change_value(total_miles_sun) unless total_miles_sun.nil?

      # Total Vehicle Revenue Miles
      revenue_miles_weekday = @revenue_miles_weekday[m.to_f]
      @worksheet[28][m + 4].change_value(revenue_miles_weekday) unless revenue_miles_weekday.nil?
      revenue_miles_sat = @revenue_miles_sat[m.to_f]
      @worksheet[29][m + 4].change_value(revenue_miles_sat) unless revenue_miles_sat.nil?
      revenue_miles_sun = @revenue_miles_sun[m.to_f]
      @worksheet[30][m + 4].change_value(revenue_miles_sun) unless revenue_miles_sun.nil?

      # Scheduled Revenue Miles: save as Total Vehicle Revenue Miles
      @worksheet[38][m + 4].change_value(revenue_miles_weekday) unless revenue_miles_weekday.nil?
      @worksheet[39][m + 4].change_value(revenue_miles_sat) unless revenue_miles_sat.nil?
      @worksheet[40][m + 4].change_value(revenue_miles_sun) unless revenue_miles_sun.nil?

      # Passenger Miles (Ops Research)
      passenger_miles_weekday = @passenger_miles_weekday[m.to_f]
      @worksheet[43][m + 4].change_value(passenger_miles_weekday) unless passenger_miles_weekday.nil?
      passenger_miles_sat = @passenger_miles_sat[m.to_f]
      @worksheet[44][m + 4].change_value(passenger_miles_sat) unless passenger_miles_sat.nil?
      passenger_miles_sun = @passenger_miles_sun[m.to_f]
      @worksheet[45][m + 4].change_value(passenger_miles_sun) unless passenger_miles_sun.nil?

      # Total Actual Hours
      total_hours_weekday = @total_hours_weekday[m.to_f]
      @worksheet[49][m + 4].change_value(total_hours_weekday) unless total_hours_weekday.nil?
      total_hours_sat = @total_hours_sat[m.to_f]
      @worksheet[50][m + 4].change_value(total_hours_sat) unless total_hours_sat.nil?
      total_hours_sun = @total_hours_sun[m.to_f]
      @worksheet[51][m + 4].change_value(total_hours_sun) unless total_hours_sun.nil?

      # Total Revenue Hours
      total_revenue_hours_weekday = @total_revenue_hours_weekday[m.to_f]
      @worksheet[54][m + 4].change_value(total_revenue_hours_weekday) unless total_revenue_hours_weekday.nil?
      total_revenue_hours_sat = @total_revenue_hours_sat[m.to_f]
      @worksheet[55][m + 4].change_value(total_revenue_hours_sat) unless total_revenue_hours_sat.nil?
      total_revenue_hours_sun = @total_revenue_hours_sun[m.to_f]
      @worksheet[56][m + 4].change_value(total_revenue_hours_sun) unless total_revenue_hours_sun.nil?

    end
  end


  private 

  def get_average_time(times_by_date)
    day_count = times_by_date.count 
    if day_count == 0
      'N/A'
    else
      total_hours = total_mins = 0
      times_by_date.each do |date, time_str|
        time_parts = time_str.split(":")
        total_hours += time_parts[0].to_i
        total_mins += time_parts[1].to_i
      end

      sum_mins = total_hours * 60 + total_mins
      average_mins = sum_mins / day_count

      hour = average_mins / 60
      min = average_mins - hour * 60

      DateTime.new(@year, 1, 1, hour, min)
    end 
  end

  def sum_monthly_trip_size(trips)
    trips.group("extract(month from pickup_time)").sum("customer_space_count + guest_count + attendant_count")
  end

  def count_monthly_days_operated(trips)
    trips.group("extract(month from runs.date)").count("distinct(runs.date)")
  end

  def monthly_miles_hours(trips)
    run_ids = trips.pluck(:run_id).uniq
    runs_rel = Run.where(id: run_ids).joins(:run_distance).group("extract(month from runs.date)")
    {
      total_miles: runs_rel.sum("run_distances.ntd_total_miles"),
      revenue_miles: runs_rel.sum("run_distances.ntd_total_revenue_miles"),
      passenger_miles: runs_rel.sum("run_distances.ntd_total_passenger_miles"),
      total_hours: runs_rel.sum("run_distances.ntd_total_hours"),
      total_revenue_hours: runs_rel.sum("run_distances.ntd_total_revenue_hours"),
    }
  end

end