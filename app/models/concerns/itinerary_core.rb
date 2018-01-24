require 'active_support/concern'

# Use with `include ItineraryCore`
module ItineraryCore
  extend ActiveSupport::Concern

  included do
    #belongs_to :trip
    #belongs_to :run
    belongs_to :address

    scope :revenue, -> { where.not(trip: nil) }
    scope :deadhead, -> { where(trip: nil) }

    def self.clear_times
      self.update_all(eta: nil, travel_time: nil, depart_time: nil)
    end

    def trip_id
      @trip_id ||= trip.id
    end

    def prev=(prev_itin)
      @prev = prev_itin
    end

    def prev 
      @prev
    end

    def next=(next_itin)
      @next = next_itin
    end

    def next
      @next
    end

    def is_begin_run?
      leg_flag == 0
    end

    def is_end_run?
      leg_flag == 3
    end

    def is_pickup?
      leg_flag == 1
    end

    def is_dropoff?
      leg_flag == 2
    end

    def ordinal 
      @ordinal ||= case leg_flag 
      when 0
        0
      when 1..2
        zero_index = (run.manifest_order || []).try(:index, itin_id)
        zero_index ? (zero_index + 1) : -1
      when 3
        run.manifest_order.size + 1
      end
    end

    def scheduled_time
      @scheduled_time ||= time || (leg_flag == 2 ? trip.pickup_time : nil) 
    end

    # scheduled time delta since midnight of day
    def time_diff
      @time_diff ||= time_portion(scheduled_time) 
    end

    def to_address
      @to_address ||= @next.address if @next
    end

    def capacity=(capacity)
      @capacity = capacity
    end

    def capacity
      @capacity
    end

    def capacity_warning=(capacity_warning)
      @capacity_warning = capacity_warning
    end

    def capacity_warning
      @capacity_warning
    end

    def itin_id 
      case leg_flag 
      when 0 
        "run_begin"
      when 1..2 # Pickup or dropoff
        "trip_#{trip_id}_leg_#{leg_flag}"
      when 3 
        "run_end"
      end
    end

    def calculate_eta! 
      # previous leg depart_time + travel_time
      self.eta = if @prev && @prev.depart_time && @prev.travel_time
        @prev.depart_time + @prev.travel_time.seconds 
      else
        time
      end

      update_depart_time

      self.save(validate: false)
    end

    def update_depart_time
      new_time = (self.eta + process_time.to_i.minutes) if self.eta
      self.depart_time = if trip && !trip.early_pickup_allowed
        new_time > time ? new_time : time
      else
        new_time
      end
    end

    # in minutes
    def wait_time
      if trip && !trip.early_pickup_allowed && time
        eta_time = eta 
        if time > eta_time
          ((time.to_i - eta.to_i) / 60.to_f).to_i 
        else
          0
        end
      else
        0
      end
    end

    # in minutes
    def process_time
      if trip
        leg_flag == 1 ? trip.passenger_load_min : trip.passenger_unload_min
      else 
        0
      end
    end

    def calculate_travel_time!
      if address && to_address && address.geocoded? && to_address.geocoded?
        params = {
          from_lat: address.latitude, 
          from_lon: address.longitude, 
          to_lat: to_address.latitude, 
          to_lon: to_address.longitude, 
          trip_datetime: eta || time
        }

        self.travel_time = TripDistanceDurationProxy.new(ENV['TRIP_PLANNER_TYPE'], params).get_drive_time.to_f
      end
    end

    def time_portion(time)
      (time.to_i - time.beginning_of_day.to_i) if time
    end
  end
end


