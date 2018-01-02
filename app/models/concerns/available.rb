require 'active_support/concern'

# Use with `include Available`
# Owner will be able to configure its availability based on Planned Leave, Daily Operating Hours and Recurring Operating Hours
module Available
  extend ActiveSupport::Concern

  included do
    has_many :operating_hours, dependent: :destroy, as: :operatable, inverse_of: :operatable
    has_many :daily_operating_hours, dependent: :destroy, as: :operatable, inverse_of: :operatable
    has_many :planned_leaves, class_name: "PlannedLeave", dependent: :destroy, as: :leavable, inverse_of: :leavable
    
    # 1. self.provider available?
    # 2. planned_leave?
    # 3. daily_operating_hour?
    # 4. (recurring) operating_hour?
    def available?(date = Date.current, time_of_day = Time.current.strftime('%H:%M'))
      time_of_day = time_of_day.strftime('%H:%M') if time_of_day && !time_of_day.is_a?(String)

      day_of_week = date.wday
      # first check provider
      if !is_provider_available?(day_of_week, time_of_day)
        false
      else
        # then check planned leave
        if is_on_leave?(date)
          false
        else
          # third, check daily operating hour configuration
          daily_hours = daily_operating_hours.for_date(date)
          if daily_hours.any?
            daily_hours.operating_for_time?(time_of_day)
          else
            # finally, check recurring operating hour configurations
            recur_hours = operating_hours.for_day_of_week(day_of_week)
            if recur_hours.any?
              recur_hours.operating_for_time?(time_of_day)
            else
              false
            end
          end
        end 
      end 
    end

    def available_between?(date = Time.current, start_time = Time.current.strftime('%H:%M'), end_time = Time.current.strftime('%H:%M'))
      start_time = start_time.strftime('%H:%M') if start_time && !start_time.is_a?(String)
      end_time = end_time.strftime('%H:%M') if end_time && !end_time.is_a?(String)

      day_of_week = date.wday
      # first check provider
      if !is_provider_available?(day_of_week, start_time) || !is_provider_available?(day_of_week, end_time)
        false
      else
        # then check planned leave
        if is_on_leave?(date)
          false
        else
          # third, check daily operating hour configuration
          daily_hours = daily_operating_hours.for_date(date)
          if daily_hours.any?
            daily_hours.operating_between_time?(start_time, end_time)
          else
            # finally, check recurring operating hour configurations
            recur_hours = operating_hours.for_day_of_week(day_of_week)
            if recur_hours.any?
              recur_hours.operating_between_time?(start_time, end_time)
            else
              false
            end
          end
        end 
      end 
    end

    private 

    def is_provider_available?(day_of_week = Date.current.wday, time_of_day = Time.current.strftime('%H:%M'))
      time_of_day = time_of_day.strftime('%H:%M') if time_of_day && !time_of_day.is_a?(String)
      
      if self.respond_to?(:provider) && !self.provider.available?(day_of_week, time_of_day)
        false
      else
        true
      end
    end

    def is_on_leave?(date = Date.current)
      planned_leave = planned_leaves.leave_on_date(date)
      # then check planned leave
      if planned_leave.present?
        true
      else
        false
      end
    end
  end
end


