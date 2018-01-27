module DispatchHelper

  def get_itineraries(run, is_recurring = false, recurring_dispatch_wday = nil)
    return [] unless run

    itins = []

    # get trips/repeating_trips
    trips = if is_recurring
      RepeatingTrip.where(id: run.weekday_assignments.for_wday(recurring_dispatch_wday).pluck(:repeating_trip_id))
    else
      run.trips
    end

    # vehicle capacity
    if run.vehicle && run.vehicle.vehicle_type
      vehicle_capacities = []
      run.vehicle.vehicle_type.vehicle_capacity_configurations.each do |config|
        vehicle_capacities << config.vehicle_capacities.pluck(:capacity_type_id, :capacity).to_h
      end
    end

    # system mobility capacity configurations
    mobility_capacities = {}
    MobilityCapacity.has_capacity.each do |c|
      mobility_capacities[[c.host_id, c.capacity_type_id]] = c.capacity
    end

    capacity_type_ids = CapacityType.by_provider(current_provider).pluck(:id)

    # trips capacities
    trip_table_name = is_recurring ? "repeating_trips" : "trips"
    trip_capacities = {}
    trips.joins(:ridership_mobilities)
      .where("ridership_mobility_mappings.capacity > 0")
      .group("#{trip_table_name}.id", "ridership_mobility_mappings.mobility_id")
      .sum("ridership_mobility_mappings.capacity").each do |k, capacity|
      trip_id = k[0]
      trip_capacities[trip_id] = {} unless trip_capacities.has_key?(trip_id)
      trip_capacity = trip_capacities[trip_id]
      mobility_id = k[1]

      capacity_type_ids.each do |c_id|
        val = trip_capacity[c_id] || 0
        val += capacity * mobility_capacities[[mobility_id, c_id]].to_i

        trip_capacity[c_id] = val
      end
    end

    # add itinerary specific data
    itins = is_recurring ? run.sorted_itineraries(true, recurring_dispatch_wday) : run.sorted_itineraries(true)
    # default occupancy by capacity type
    occupancy = {}
    capacity_type_ids.each do |c_id|
      occupancy[c_id] = 0
    end

    # the occupancy change in each itinerary
    delta = nil
    # PickUp: add (delta_unit = 1), DropOff: subtract (delta_unit = -1)
    delta_unit = 1 
    
    itins.each do |itin|
      trip = itin.trip

      # calculate latest occupancy based on the change in previous leg
      if delta && !delta.blank?
        occupancy.merge!(delta) { |k, a_value, b_value| a_value + delta_unit * b_value }
      end
      # save occupancy snapshot
      itin.capacity = occupancy.dup

      # check if trip capacity > vehicle capacity
      itin.capacity_warning = false
      if vehicle_capacities && vehicle_capacities.any?
        has_enough_capacity = false
        vehicle_capacities.each do |cap_data|
          capacity_met = true
          occupancy.each do |c_id, val|
            if cap_data[c_id].to_i < val
              capacity_met = false
              break 
            end
          end

          if capacity_met
            has_enough_capacity = true
            break
          end
        end
        itin.capacity_warning = true if !has_enough_capacity
      else 
        itin.capacity_warning = true
      end

      # log the occupancy change in this leg for occupancy calculation in next leg
      if itin.leg_flag == 1 && (is_recurring || !TripResult::NON_DISPATCHABLE_CODES.include?(trip.trip_result.try(:code)))
        delta = trip_capacities[trip.id]
        delta_unit = 1
      elsif itin.leg_flag == 2
        delta = trip_capacities[trip.id]
        delta_unit = -1
      end
    end

    itins
  end

  def run_summary(run)
    if run
      trip_count = run.trips.count
      trips_part = if trip_count == 0
        "No trip" 
      elsif trip_count == 1
        "1 trip"
      else
        "#{trip_count} trips"
      end

      vehicle = run.vehicle
      if vehicle 
        vehicle_overdue_check = get_vehicle_warnings(vehicle, run)
        vehicle_part = "<span class='#{vehicle_overdue_check[:class_name]}' title='#{vehicle_overdue_check[:tips]}'>Vehicle: #{vehicle.try(:name) || '(empty)'}</span>"
      else
        vehicle_part = "<span>Vehicle: (empty)</span>"
      end

      driver = run.driver
      if driver 
        driver_overdue_check = get_driver_warnings(driver, run)
        driver_part = "<span class='#{driver_overdue_check[:class_name]}' title='#{driver_overdue_check[:tips]}'>Driver: #{driver.try(:user_name) || '(empty)'}</span>"
      else
        driver_part = "<span>Driver: (empty)</span>"
      end

      run_time_part = if !run.scheduled_start_time && !run.scheduled_end_time
        "Run time: (not specified)"
      else
        "Run Time: #{format_time_for_listing(run.scheduled_start_time)} - #{format_time_for_listing(run.scheduled_end_time)}"
      end
      
      [vehicle_part, driver_part, run_time_part, trips_part].join(', ')
    end
  end

  def recurring_run_summary(run, wday = Date.today.wday)
    if run
      trip_count = run.weekday_assignments.for_wday(wday).count
      trips_part = if trip_count == 0
        "No trip" 
      elsif trip_count == 1
        "1 trip"
      else
        "#{trip_count} trips"
      end

      vehicle = run.vehicle
      if vehicle 
        vehicle_overdue_check = get_vehicle_warnings(vehicle, run)
        vehicle_part = "<span class='#{vehicle_overdue_check[:class_name]}' title='#{vehicle_overdue_check[:tips]}'>Vehicle: #{vehicle.try(:name) || '(empty)'}</span>"
      else
        vehicle_part = "<span>Vehicle: (empty)</span>"
      end

      driver = run.driver
      if driver 
        driver_overdue_check = get_driver_warnings(driver, run)
        driver_part = "<span class='#{driver_overdue_check[:class_name]}' title='#{driver_overdue_check[:tips]}'>Driver: #{driver.try(:user_name) || '(empty)'}</span>"
      else
        driver_part = "<span>Driver: (empty)</span>"
      end

      run_time_part = if !run.scheduled_start_time && !run.scheduled_end_time
        "Run time: (not specified)"
      else
        "Run Time: #{format_time_for_listing(run.scheduled_start_time)} - #{format_time_for_listing(run.scheduled_end_time)}"
      end
      
      [vehicle_part, driver_part, run_time_part, trips_part].join(', ')
    end
  end

  private

  def time_portion(time)
    (time - time.beginning_of_day) if time
  end

end