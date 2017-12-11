module AvailabilityHelper

  def get_availability_tick_hour_gap
    min_hour = current_provider.driver_availability_min_hour || 6
    max_hour = current_provider.driver_availability_max_hour || 22

    # tick gaps
    ((max_hour - min_hour) / 8.to_f).ceil
  end

  def get_availability_chart_ticks(interval_min = 30)
    min_hour = current_provider.driver_availability_min_hour || 6
    max_hour = current_provider.driver_availability_max_hour || 22

    # tick gaps
    tick_gap_hour = ((max_hour - min_hour) / 8.to_f).ceil
    interval_count = (max_hour - min_hour) * 60 / interval_min

    # get hour tick lines
    start_hour = min_hour
    ticks = []

    while start_hour < max_hour do
      tick = [start_hour]
      if (start_hour - min_hour) % tick_gap_hour == 0
        tick << format_hour_label(start_hour) 
      else
        tick << ""
      end

      start_hour += interval_min.to_f / 60

      ticks << tick
    end

    ticks
  end

  def format_hour_label(hour)
    if hour == 0 || hour == 24
      "12am"
    elsif hour == 12
      "12pm"
    elsif hour < 12
      min = (hour - hour.to_i) * 60
      min == 0 ? "#{hour.to_i}am" : "#{hour.to_i}:#{min.to_i}am"
    else
      hour -= 12
      min = (hour - hour.to_i) * 60
      min == 0 ? "#{hour.to_i}pm" : "#{hour.to_i}:#{min.to_i}pm"
    end 
  end

  def hour_tooltip(is_on_leave, is_provider_unavailable, is_all_day, start_hour, end_hour, provider_hours)
    if is_on_leave
      "Planned Leave"
    elsif is_provider_unavailable
      "Provider not operating"
    elsif is_all_day
      if provider_hours.blank? || provider_hours == [0, 24]
        "All day"
      else
        "#{format_hour_label(provider_hours[0].to_f)} - #{format_hour_label(provider_hours[1].to_f)}"
      end
    elsif start_hour && end_hour
      "#{format_hour_label(start_hour.to_f)} - #{format_hour_label(end_hour.to_f)}"
    end
  end

end