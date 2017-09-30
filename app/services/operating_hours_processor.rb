class OperatingHoursProcessor
  attr_reader :operatable, :hour_params

  def initialize(operatable, params = {})
    @operatable = operatable
    @hour_params = params
  end

  def process!
    @hour_params[:hours] ||= {}
    hours = @operatable.hours_hash
    if !hours.empty? and hours.length < 7
      hours.each_pair { |day, h| h.destroy }
      hours = {}
    end
    if hours.empty?
      (0..6).each do |d|
        hours[d] = @operatable.operating_hours.new day_of_week: d
      end
    end
    errors = false

    @hour_params[:hours].each_pair do |day, value|
      begin
        day = day.to_i
        day_hours = hours[day]
        if day_hours.nil?
          day_hours = @operatable.operating_hours.new day_of_week: day
        end
        case value
        when 'unavailable'
          day_hours.make_unavailable
        when 'open24'
          day_hours.make_24_hours
        when 'open'
          day_hours.start_time = @hour_params[:start_hour][day.to_s]
          day_hours.end_time = @hour_params[:end_hour][day.to_s]
        else
          @operatable.errors.add :operating_hours, 'must be "unavailable", "open24", or "open".'
          raise ActiveRecord::RecordInvalid.new(@operatable)
        end
        day_hours.save!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        errors = true
      end
    end

    errors
  end

end