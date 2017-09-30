require 'active_support/concern'

# Use with `include Operatable`
# Owner will be able to configure its availability
module Operatable
  extend ActiveSupport::Concern

  included do
    has_many :operating_hours, class_name: :OperatingHours, dependent: :destroy, as: :operatable, inverse_of: :operatable
    
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
        elsif hours.is_24_hours?
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
        elsif hours.is_24_hours?
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
  end
end


