require 'json'
require 'net/http'

class RunStatsCalculator
  attr_reader :run

  def initialize(run_id)
    @run = Run.find_by_id(run_id)
  end

  # calculate run distances
  #    total, revenue, non-revenue, deadhead, passenger miles
  def process_distance
    return unless @run && @run.complete?

    itins = @run.sorted_itineraries(true)
    itins = append_capacity_to_itineraries(itins)

    return if itins.empty?

    total_dist = 0
    deadhead_from_garage = 0
    revenuse_miles = 0
    non_revenue_miles = 0
    deadhead_to_garage = 0
    passenger_miles = 0

    #NTD related
    non_ntd_miles = 0
    non_ntd_passenger_miles = 0

    from_address = @run.from_garage_address || @run.vehicle.try(:garage_address)
    to_address = itins.first.address
    time = @run.scheduled_start_time
    
    deadhead_from_garage = get_drive_distance(from_address, to_address, time)

    itins.each_with_index do |itin, index|
      next if index < 1

      from_address = itins[index - 1].address
      to_address = itin.address
      time = itin.time

      dist = get_drive_distance(from_address, to_address, time)
      if itin.capacity.to_f > 0
        revenuse_miles += dist 
        passenger_miles += dist * itin.capacity.to_f
      else
        non_revenue_miles += dist
      end    

      unless itin.trip.try(:ntd_reportable?)     
        non_ntd_miles += dist
        non_ntd_passenger_miles += dist * itin.capacity.to_f
      end
    end

    last_stop = itins.last
    from_address = last_stop.address
    to_address = @run.to_garage_address || @run.vehicle.try(:garage_address)
    time = last_stop.time
    deadhead_to_garage = get_drive_distance(from_address, to_address, time)

    total_dist = deadhead_from_garage + revenuse_miles + non_revenue_miles + deadhead_to_garage

    run_distance = @run.run_distance || RunDistance.new(run: @run)
    run_distance.total_dist = total_dist
    run_distance.revenue_miles = revenuse_miles
    run_distance.non_revenue_miles = non_revenue_miles
    run_distance.deadhead_from_garage = deadhead_from_garage
    run_distance.deadhead_to_garage = deadhead_to_garage
    run_distance.passenger_miles = passenger_miles
    #NTD
    run_distance.ntd_total_miles = total_dist - non_ntd_miles
    run_distance.ntd_total_revenue_miles = revenuse_miles + non_revenue_miles - non_ntd_miles
    run_distance.ntd_total_passenger_miles = passenger_miles - non_ntd_passenger_miles
    run_distance.ntd_total_hours = @run.duration_in_hours * (run_distance.ntd_total_miles / run_distance.total_dist) #preportional to distance %
    run_distance.ntd_total_revenue_hours = @run.duration_in_hours * (run_distance.ntd_total_revenue_miles / run_distance.total_dist)

    run_distance.save
  end

  # calculate ETA for each itinerary
  def process_eta
    return unless @run

    itins = @run.sorted_itineraries

    return if itins.empty?

    unless itins.first.is_begin_run?
      run_begin_itin = @run.build_begin_run_itinerary
      run_begin_itin.save
      itins.insert(0, run_begin_itin)  
    end
    unless itins.last.is_end_run? 
      run_end_itin = @run.build_end_run_itinerary
      run_end_itin.save
      itins << run_end_itin
    end

    eta_info = {}
    itin_count = itins.size
    itins.each_with_index do |itin, index|
      if index < (itin_count - 1)
        itin.next = itins[index + 1]
      end

      if index > 0
        itin.prev = itins[index - 1]    
      end  

      if index < (itin_count - 1)
        itin.calculate_travel_time! 
      else
        itin.calculate_eta! 
      end
      eta_info[itin.itin_id] = {
        scheduled_time: itin.time,
        eta: itin.eta,
        wait_time: itin.wait_time,
        process_time: itin.process_time,
        depart_time: itin.depart_time,
        travel_time: itin.travel_time    
      }
    end

    eta_info
  end

  def append_capacity_to_itineraries(itins = [])
    # calculate occupancy
    occupancy = 0
    delta = 0
    itins.each do |itin|
      occupancy += delta
      itin.capacity = occupancy

      trip = itin.trip
      next unless trip

      if itin.leg_flag. == 1
        delta = trip.trip_size unless TripResult::NON_DISPATCHABLE_CODES.include?(trip.trip_result.try(:code))
      elsif itin.leg_flag == 2
        delta = -1 * trip.trip_size
      end
    end

    itins
  end

  def get_drive_distance(from_addr, to_addr, time = DateTime.now)
    calculator = get_dist_duration_calculator(from_addr, to_addr, time)
    calculator.get_drive_distance.to_f
  end

  def get_drive_duration(from_addr, to_addr, time = DateTime.now)
    calculator = get_dist_duration_calculator(from_addr, to_addr, time)
    calculator.get_drive_time.to_f
  end

  def get_dist_duration_calculator(from_addr, to_addr, time = DateTime.now)
    from_lat = from_addr.try(:latitude)
    from_lon = from_addr.try(:longitude)
    to_lat = to_addr.try(:latitude)
    to_lon = to_addr.try(:longitude)

    params = {
      from_lat: from_lat, 
      from_lon: from_lon, 
      to_lat: to_lat, 
      to_lon: to_lon, 
      trip_datetime: time
    }
    
    TripDistanceDurationProxy.new(ENV['TRIP_PLANNER_TYPE'], params)
  end

  def time_portion(time)
    (time - time.beginning_of_day) if time
  end
end
