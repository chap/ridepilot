module ScheduleHelpers
  
  # Returns an array of the schedule's weekly rules
  def schedule_weekly_rules
    schedule.to_hash[:rrules].select {|rule| rule[:rule_type] == "IceCube::WeeklyRule" }
  end
  
  # Returns the days of the week that a schedule 
  def schedule_weekdays
    schedule_weekly_rules
      .map {|rule| rule[:validations][:day] }
      .flatten.compact
  end
  
  # Pulls the start date from the Schedule object
  def schedule_start_date
    schedule.to_hash[:start_date]
  end
  
  # Gets the number of weeks between two dates
  def weeks_offset(date1, date2)
    ((date1.to_date.beginning_of_week - date2.to_date.beginning_of_week).to_i / 7).abs
  end
  
  # Determines if the (start_date..end_date) ranges of the two schedules overlap
  def date_ranges_overlap?(other_record)
    a1, b1 = start_date, end_date
    a2, b2 = other_record.start_date, other_record.end_date
    ((a1.nil? && b1.nil?) || (a2.nil? && b2.nil?)) ||  # TRUE if either range has nil start and end dates
    date_in_range?(a1, a2, b2) ||                      # TRUE if any endpoint falls within the other record's range
    date_in_range?(b1, a2, b2) ||  
    date_in_range?(a2, a1, b1) ||  
    date_in_range?(b2, a1, b1) 
  end
  
  # Determines if a date falls within a given range (a..b), allowing for open-ended ranges
  def date_in_range?(date, a, b)
    return false if date.nil?   # FALSE if DATE is nil
    !( ( a.present? && date < a ) || ( b.present? && date > b ) )
  end
  
  # Determines if the passed date falls in this schedule's active range
  def date_in_active_range?(date)
    date_in_range?(date, start_date, end_date)
  end
  
  # Checks for intersection of two arithmetic sequences
  def recurrences_intersect?(offset, interval1, interval2)
    (offset % (interval1.gcd(interval2))).zero?
  end
  
  # Checks if this record's schedule conflicts with another record's schedule
  # Currently, only checks for weekly recurrence conflicts
  def schedule_conflicts_with?(other_record)
    # Check if there is any day of week overlap, return false if not.
    return false if (schedule_weekdays & other_record.schedule_weekdays).empty?
    
    # Check if the date ranges of the schedule overlap
    return false unless date_ranges_overlap?(other_record)

    # Check for collision based on start date and repeat interval
    offset = weeks_offset(schedule_start_date, other_record.schedule_start_date)
    return recurrences_intersect?(offset, repetition_interval, other_record.repetition_interval)
  end
  
  # Sets an attribute in the schedule_attributes hash, converting dates to strings
  # to avoid errors
  def set_schedule_attribute(attr, value)
    sched_attrs = self.try(:schedule_attributes).to_h
    return false unless sched_attrs.present?
    sched_attrs[attr] = value
    sched_attrs = sched_attrs.map do |k,v|
      [k, [Date, Time, DateTime].include?(v.class) ? v.to_s : v]
    end.to_h
    self.schedule_attributes = sched_attrs
  end
  
end
