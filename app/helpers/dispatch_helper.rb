module DispatchHelper

  def get_itineraries(run, is_recurring = false, recurring_dispatch_wday = nil)
    return [] unless run

    itins = []

    trips = if is_recurring
      RepeatingTrip.where(id: run.weekday_assignments.for_wday(recurring_dispatch_wday).pluck(:repeating_trip_id))
    else
      run.trips
    end

    manifest_order = if is_recurring
      run.repeating_run_manifest_orders.for_wday(recurring_dispatch_wday).first.try(:manifest_order)
    else
      run.manifest_order
    end

    trips.each do |trip|
      trip_data = {
        trip: trip,
        trip_id: trip.id,
        is_recurring: is_recurring ? true : trip.repeating_trip_id.present?,
        customer: trip.customer.try(:name),
        phone: [trip.customer.phone_number_1, trip.customer.phone_number_2].compact,
        comments: trip.notes,
        result: is_recurring ? nil : (trip.trip_result.try(:name) || 'Pending')
      }

      pickup_sort_key = time_portion(trip.pickup_time)
      itin_id = "trip_#{trip.id}_leg_1"
      itins << trip_data.merge(
        id: itin_id,
        ordinal: ((manifest_order || []).any? ? manifest_order.index(itin_id) : -1),
        leg_flag: 1,
        time: trip.pickup_time,
        sort_key: pickup_sort_key,
        address: trip.pickup_address.try(:one_line_text)
      )

      if is_recurring || !TripResult::CANCEL_CODES_BUT_KEEP_RUN.include?(trip.trip_result.try(:code))
        dropoff_sort_key = trip.appointment_time ? time_portion(trip.appointment_time) : time_portion(trip.pickup_time)
        itin_id = "trip_#{trip.id}_leg_2"
        itins << trip_data.merge(
          id: itin_id,
          ordinal: ((manifest_order || []).any? ? manifest_order.index(itin_id) : -1),
          leg_flag: 2,
          time: trip.appointment_time,
          sort_key: dropoff_sort_key,
          address: trip.dropoff_address.try(:one_line_text)
        )
      end
    end

    itins = if manifest_order && manifest_order.any?
      itins.sort_by { |itin| [itin[:ordinal] >= 0, itin[:ordinal], itin[:sort_key], itin[:leg_flag]] }
    else
      itins.sort_by { |itin| [itin[:sort_key], itin[:leg_flag]] }
    end

    # calculate occupancy
    occupancy = 0
    delta = 0
    itins.each do |itin|
      trip = itin[:trip]
      occupancy += delta
      itin[:capacity] = occupancy

      if itin[:leg_flag] == 1
        delta = trip.trip_size unless !is_recurring && TripResult::NON_DISPATCHABLE_CODES.include?(trip.trip_result.try(:code))
      elsif itin[:leg_flag] == 2
        delta = -1 * trip.trip_size
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