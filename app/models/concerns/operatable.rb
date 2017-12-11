require 'active_support/concern'

# Use with `include Operatable`
# Owner will be able to configure its availability
module Operatable
  extend ActiveSupport::Concern

  included do
    has_many :operating_hours, dependent: :destroy, as: :operatable, inverse_of: :operatable
    
    def hours_hash
      result = {}
      self.operating_hours.each do |h|
        result[h.day_of_week] = h
      end
      result
    end
    
    def available?(day_of_week = Time.current.wday, time_of_day = Time.current.strftime('%H:%M'))
      # If no operating hours are defined, assume available
      return true unless operating_hours.any?
      
      if hours = operating_hours.where(day_of_week: day_of_week).first
        if hours.is_unavailable?
          return false
        elsif hours.is_all_day?
          return true
        elsif hours.start_time > hours.end_time
          return time_of_day >= hours.start_time.strftime('%H:%M') || time_of_day <= hours.end_time.strftime('%H:%M')
        elsif hours.start_time != hours.end_time
          return time_of_day.between? hours.start_time.strftime('%H:%M'), hours.end_time.strftime('%H:%M')
        else
          # Some edge condition...
          false
        end
      else
        # No hours defined for that day, assume unavailable
        false
      end
    end

    def available_between?(day_of_week = Time.current.wday, start_time = Time.current.strftime('%H:%M'), end_time = Time.current.strftime('%H:%M'))
      # If no operating hours are defined, assume available
      return true unless operating_hours.any?
      
      if hours = operating_hours.where(day_of_week: day_of_week).first
        if hours.is_unavailable?
          false
        elsif hours.is_all_day?
          true
        elsif hours.start_time != hours.end_time
          (start_time && start_time.between?(hours.start_time.strftime('%H:%M'), hours.end_time.strftime('%H:%M'))) && 
          (end_time && end_time.between?(hours.start_time.strftime('%H:%M'), hours.end_time.strftime('%H:%M')))
        else
          # Some edge condition...
          false
        end
      else
        # No hours defined for that day, assume unavailable
        false
      end
    end

    # get number index of operating hours
    def hours_per_day_of_week(day_of_week)
      op_hour = self.operating_hours.for_day_of_week(day_of_week).first
      if op_hour
        if op_hour.is_unavailable
          p_min_hour = 0
          p_max_hour = 0
        elsif op_hour.is_all_day
          p_min_hour = 0
          p_max_hour = 24
        elsif op_hour.start_time && op_hour.end_time
          p_min_hour = (op_hour.start_time - op_hour.start_time.at_beginning_of_day) / 3600.0
          p_max_hour = (op_hour.end_time - op_hour.end_time.at_beginning_of_day) / 3600.0
          p_max_hour = 24 if p_max_hour == 0
        end

        [p_min_hour, p_max_hour]
      else
        []
      end
    end
  end
end


