class Run < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include RunCore
  include PublicActivity::Common

  acts_as_paranoid # soft delete

  has_paper_trail

  serialize :manifest_order, Array

  FIELDS_FOR_COMPLETION = [
    :unpaid_driver_break_time,
    :paid,
  ].freeze
  
  BATCH_ACTIONS = [
    :cancel,
    :delete
  ].freeze

  has_many :trips, -> { order(:pickup_time) }, :dependent => :nullify
  has_many :itineraries, :dependent => :destroy
  belongs_to :repeating_run

  has_one :run_distance

  belongs_to :from_garage_address, -> { with_deleted }, class_name: 'GarageAddress', foreign_key: 'from_garage_address_id'
  accepts_nested_attributes_for :from_garage_address, update_only: true
  belongs_to :to_garage_address, -> { with_deleted }, class_name: 'GarageAddress', foreign_key: 'to_garage_address_id'
  accepts_nested_attributes_for :to_garage_address, update_only: true

  accepts_nested_attributes_for :trips

  before_validation :fix_dates
  before_update :check_vehicle_change
  before_update :check_manifest_change
  after_update :apply_manifest_changes

  validate                  :name_uniqueness
  normalize_attribute :name, :with => [ :strip ]
  
  validates_date            :date
  validates_datetime        :actual_start_time, allow_blank: true
  validates_datetime        :actual_end_time, after: :actual_start_time, allow_blank: true
  validates_numericality_of :start_odometer, allow_nil: true
  validates_numericality_of :end_odometer, allow_nil: true
  validates_numericality_of :end_odometer, greater_than: -> (run){ run.start_odometer }, less_than: -> (run){ run.start_odometer + 500 }, if: -> (run){ run.start_odometer.present? }, allow_nil: true
  validates_numericality_of :unpaid_driver_break_time, allow_nil: true
  validate                  :within_advance_day_scheduling
  validate                  :driver_availability
  validate                  :vehicle_availability

  scope :after,                  -> (date) { where('runs.date > ?', date) }
  scope :after_today,            -> { where('runs.date > ?', Date.today) }
  scope :today_and_future,       -> { where('runs.date >= ?', Date.today) }
  scope :prior_to,               -> (date) { where('runs.date < ?', date) }
  scope :today_and_prior,        -> { where('runs.date <= ?', Date.today) }
  scope :for_date,               -> (date) { where(date: date) }
  scope :for_date_range,         -> (start_date, end_date) { where("runs.date >= ? and runs.date < ?", start_date, end_date) }
  scope :overlapped,             -> (run) { for_date(run.date).time_overlaps_with(run.scheduled_start_time, run.scheduled_end_time) }
  scope :this_week,              -> {
    where(date: DateTime.now.in_time_zone.beginning_of_week.to_date..DateTime.now.in_time_zone.end_of_week.to_date)
  }
  # Daily runs which conflict with another Repeating Run's schedule
  scope :conflicts_with_schedule, -> (repeating_run) do
    not_a_child_of(repeating_run)
    .select {|r| repeating_run.date_in_active_range?(r.date) && repeating_run.schedule.occurs_on?(r.date)}
  end

  scope :complete,               -> { where(complete: true) }
  scope :incomplete,             -> { where('complete is NULL or complete = ?', false) }
  scope :incomplete_on,          -> (date) { incomplete.for_date(date) }
  scope :with_odometer_readings, -> { where("start_odometer IS NOT NULL and end_odometer IS NOT NULL") }
  scope :repeating_based_on,     ->(scheduler) { where(repeating_run_id: scheduler.try(:id)) }
  scope :other_than,             -> (run) { run.new_record? ? all : where.not(id: run.id) }
  scope :not_a_child_of,         -> (repeating_run) { where.not(repeating_run_id: [repeating_run.id].compact) }
  scope :daily,                  -> {where(repeating_run_id: nil)}
  scope :recurring,              -> {where.not(repeating_run_id: nil)}
  scope :cancelled,              -> {where(cancelled: true)}
  scope :not_cancelled,          -> {where('cancelled is NULL or cancelled = ?', false)}

  scope :other_overlapped_runs, -> (run) { overlapped(run).other_than(run) }

  scope :default_order, -> { order(:date, :scheduled_start_time_string, :scheduled_end_time_string, :name) }

  CAB_RUN_ID = -1 # id for cab runs
  UNSCHEDULED_RUN_ID = -2 # id for unscheduled run (empty container)
  STANDBY_RUN_ID = -3 # standby queue id
  TRIP_UNMET_NEED_ID = -4 # put trip to unmet need
  
  # based on recurring dispatching, batch assign recurring trip instances to recurring run instances
  def self.batch_update_recurring_trip_assignment!
    recurring.each do |r|
      next unless r && r.manifest_order.empty?
      
      r.update_recurring_trip_assignment!
    end
  end

  # based on recurring dispatching, assign recurring trip instances to recurring run instances
  def update_recurring_trip_assignment!
    return unless self.date

    rr = self.repeating_run
    return unless rr.present? 

    day_of_week = self.date.wday

    rr_manifest_order = rr.repeating_run_manifest_orders.for_wday(day_of_week).first.try(:manifest_order) || []
  
    run_manifest_order = []

    if rr_manifest_order.any?
      rr_manifest_order.each do |mo|
        next if mo.blank?
        # mo format: "trip_{trip_id}_leg_{leg_id}", e.g., "trip_14_leg_!"
        mo_pieces = mo.split('_')
        # get recurring trip id
        rtrip_id = mo_pieces[1].try(:to_i)

        # get recurring trip
        rtrip = RepeatingTrip.find_by_id(rtrip_id)
        next unless rtrip.present?

        # get trip instance for run date
        trip = rtrip.trips.for_date(date).first

        next unless trip.present?

        # make a copy and update run manifest order
        new_mo_pieces = mo_pieces.dup
        new_mo_pieces[1] = trip.id
        run_manifest_order << new_mo_pieces.join("_")

        unless trip.run_id.present?
          # assign trip to run
          trip.run = self
          trip.save(validate: false)
        end
      end
    else
      rr_weekday_assignments = rr.weekday_assignments.for_wday(day_of_week)
      if rr_weekday_assignments.any?
        rr_weekday_assignments.each do |assignment|
          rtrip = assignment.repeating_trip
          next unless rtrip.present?

          # get trip instance for run date
          trip = rtrip.trips.for_date(date).first
          next unless trip.present?

          unless trip.run_id.present?
            # assign trip to run
            trip.run = self
            trip.save(validate: false)
          end
        end
      end
    end

    if run_manifest_order.any?
      self.manifest_order = run_manifest_order 
      self.save(validate: false)
    end

    # create itineraries
    Itinerary.transaction do
      build_begin_run_itinerary.save
      self.trips.each do |trip|
        build_itinerary(trip.pickup_time, trip.pickup_address, trip.id, 1).save
        build_itinerary(trip.appointment_time, trip.dropoff_address, trip.id, 2).save
      end
      build_end_run_itinerary.save
    end
  end

  # "Cancels" a run: mark as cancelled and unschedule everything
  def cancel!
    self.cancelled = true
    unschedule!
  end

  # unschedule trips
  def unschedule!(auto_save = true)
    self.manifest_order = nil
    self.save(validate: false) if auto_save
    
    trips.clear # Doesn't actually destroy the records, just removes the association
    itineraries.delete_all
  end
  
  # Cancels all runs in the collection, returning the count of trips removed from runs
  def self.cancel_all
    self.update_all(manifest_order: nil)

    run_ids = self.all.pluck(:id)
    Trip.where(run_id: run_ids).update_all(run_id: nil)
    Itinerary.where(run_id: run_ids).delete_all
  end

  def add_trip_manifest!(trip_id)
    # remove it first in case same trip record was left previously
    delete_trip_manifest!(trip_id)

    #scan from the beginning to injert based on scheduled_pickup_time
    trip = Trip.find_by_id trip_id
    if trip
      trip_pickup_time = trip.pickup_time
      trip_appt_time = trip.appointment_time
      pickup_index = nil 
      appt_index = nil

      manifest_order_array = self.manifest_order
      manifest_order_array.each_with_index do |leg_name, index|
        leg_name_parts = leg_name.split('_')
        leg_trip_id = leg_name_parts[1]
        is_pickup = leg_name_parts[3] == '1'
        a_trip = Trip.find_by_id leg_trip_id
        if a_trip 
          action_time = is_pickup ? a_trip.pickup_time : a_trip.appointment_time
          next unless action_time

          pickup_index = index if !pickup_index && action_time.to_s(:time_utc) > trip_pickup_time.to_s(:time_utc)

          if !appt_index
            if trip_appt_time
              appt_index = index if action_time.to_s(:time_utc) > trip_appt_time.to_s(:time_utc)
              appt_index += 1 if pickup_index && pickup_index == appt_index
            else
              appt_index = pickup_index + 1 if pickup_index
            end
          end

          break if pickup_index && appt_index
        end
      end

      is_run_end_included = manifest_order_array.last == 'run_end'
      last_itin_spot = is_run_end_included ? (manifest_order_array.size - 1) : manifest_order_array.size

      unless pickup_index
        pickup_index = last_itin_spot
        appt_index = last_itin_spot + 1
      else 
        unless appt_index
          appt_index = last_itin_spot + 1
        end
      end

      # Injert at certain index
      manifest_order_array.insert pickup_index, "trip_#{trip_id}_leg_1" if pickup_index && pickup_index <= manifest_order_array.size
      manifest_order_array.insert appt_index, "trip_#{trip_id}_leg_2" if appt_index && appt_index <= manifest_order_array.size
      self.manifest_order = manifest_order_array
      self.save(validate: false)
    end

    add_trip_itineraries!(trip_id)
  end

  def delete_trip_manifest!(trip_id)
    unless self.manifest_order.blank? 
      self.manifest_order.delete "trip_#{trip_id}_leg_1"
      self.manifest_order.delete "trip_#{trip_id}_leg_2"
      self.save(validate: false)
    end

    remove_trip_itineraries!(trip_id)
  end

  def sorted_itineraries(revenue_only = false)
    itins = itineraries
    itins = itins.revenue if revenue_only

    if itins.empty?
      # begin run
      itins << build_begin_run_itinerary unless revenue_only

      # trip related revenue itineraries
      self.trips.each do |trip|
        itins << build_itinerary(trip.pickup_time, trip.pickup_address, trip.id, 1)

        if !TripResult::CANCEL_CODES_BUT_KEEP_RUN.include?(trip.trip_result.try(:code))
          itins << build_itinerary(trip.appointment_time, trip.dropoff_address, trip.id, 2)
        end
      end

      # end run
      itins << build_end_run_itinerary unless revenue_only
    end

    if manifest_order.blank?
      itins = itins.sort_by { |itin| [itin.time_diff, itin.leg_flag] }
    else
      manifest_order.insert(0, "run_begin") if manifest_order.first != 'run_begin'
      manifest_order << "run_end" if manifest_order.last != 'run_end'

      itins = itins.sort_by{|itin| manifest_order.index(itin.itin_id).to_i}
    end

    itins
  end

  def build_begin_run_itinerary
    from_garage_address = self.from_garage_address || self.vehicle.try(:garage_address)
    build_itinerary(self.scheduled_start_time, from_garage_address, nil, 0)
  end

  def build_end_run_itinerary
    to_garage_address = self.to_garage_address || self.vehicle.try(:garage_address)
    build_itinerary(self.scheduled_end_time, to_garage_address, nil, 3)
  end

  # scheduled_time, address, trip, flag
  def build_itinerary(scheduled_time, address, trip_id, leg_flag)
    Itinerary.new(time: scheduled_time, address: address, run: self, trip_id: trip_id, leg_flag: leg_flag)
  end

  def add_trip_itineraries!(trip_id)
    if self.itineraries.where(trip_id: trip_id).empty?
      trip = Trip.find_by_id(trip_id) 
      if trip 
        build_itinerary(trip.pickup_time, trip.pickup_address, trip_id, 1).save
        build_itinerary(trip.appointment_time, trip.dropoff_address, trip_id, 2).save
        self.itineraries.clear_times! #clear other itins times
      end
    end
  end

  def remove_trip_itineraries!(trip_id)
    trip_itins = self.itineraries.where(trip_id: trip_id)
    if trip_itins.any?
      self.itineraries.where(trip_id: trip_id).delete_all
      self.itineraries.clear_times! #clear other itins times
    end
  end

  def as_calendar_json
    {
      id: id,
      start: scheduled_start_time ? scheduled_start_time.iso8601 : nil,
      end: scheduled_end_time ? scheduled_end_time.iso8601 : nil,
      title: label,
      resource: date.to_date.to_s(:js),
      className: valid_as_daily_run? ? 'valid' : 'invalid'
    }
  end

  def manifest_slack_travel_times
    slack_info = []
    itineraries.where.not(time: nil).where.not(eta: nil)
      .includes(trip: :customer).references(trip: :customer)
      .pluck(:time, :eta, :leg_flag, :trip_id, "customers.first_name || '' || customers.last_name").each do |itin|
      time = (itin[0] - itin[0].beginning_of_day) / 3600.0
      eta = (itin[1] - itin[1].beginning_of_day) / 3600.0
      is_late = eta > time
      slack_time = ((eta - time) * 60)
      slack_info << {
        time_point: (is_late ? eta : time),
        slack_time: (slack_time > 0 ? slack_time.ceil : slack_time.floor),
        leg_flag: itin[2],
        trip_id: itin[3],
        customer: itin[4]
      }
    end

    slack_info.sort_by{|x| x[:time_point]}
  end

  def self.fake_cab_run
    Run.new name: 'Cab', id: Run::CAB_RUN_ID
  end

  def self.fake_standby_run
    Run.new name: 'Standby', id: Run::STANDBY_RUN_ID
  end

  def self.fake_unscheduled_run
    Run.new name: 'Unscheduled', id: Run::UNSCHEDULED_RUN_ID
  end

  def self.update_prior_run_complete_status!
    
    Run.prior_to(Date.today).where(provider: Provider.active.pluck(:id)).incomplete.each do |r|
      if r.completable?
        r.set_complete!
      end
    end
  end

  def completable?
    start_odometer.present? && end_odometer.present? && start_odometer < end_odometer &&
    vehicle_id.present?  && driver_id.present?
    (from_garage_address || vehicle.try(:garage_address)) &&
    (to_garage_address || vehicle.try(:garage_address)) &&
    trips.incomplete.empty?  &&
    check_provider_fields_required_for_run_completion 
  end

  # lists incomplete reason
  def incomplete_reason
    return [] if complete?

    reasons = []

    unless driver_id
      reasons << "Driver not assigned"
    end
    unless vehicle_id
      reasons << "Vehicle not assigned"
    end
    unless start_odometer
      reasons << "Missing beginning mileage"
    end
    unless end_odometer
      reasons << "Missing ending mileage"
    end

    (provider.fields_required_for_run_completion & Run::FIELDS_FOR_COMPLETION.map(&:to_s)).each do |extra_field|
      if extra_field == "paid" && self.send(extra_field).nil?
        reasons << "Paid field is not specified"
      elsif extra_field == "unpaid_driver_break_time" && self.send(extra_field).nil?
        reasons << "Driver Unpaid Break Time field is not specified"
      end
    end

    if trips.incomplete.any?
      reasons << "Has #{trips.incomplete.count} pending trip(s)"
    end

    unless (from_garage_address || vehicle.try(:garage_address))
      reasons << "Missing start location"
    end

    unless (to_garage_address || vehicle.try(:garage_address)) 
      reasons << "Missing end location"
    end

    if reasons.empty?
      reasons << "No missing data, please go to run details page to complete it"
    end

    reasons
  end

  def set_complete!(user = nil)
    if !self.from_garage_address
      self.from_garage_address = self.vehicle.try(:garage_address).try(:dup)
    end
    if !self.to_garage_address
      self.to_garage_address = self.vehicle.try(:garage_address).try(:dup)
    end
    self.complete = true
    self.uncomplete_reason = nil
    self.save(validate: false)
    RunDistanceCalculationWorker.perform_async(self.id)
    TrackerActionLog.complete_run(self, user)
  end

  def set_incomplete!(reason = nil, user = nil)
    self.complete = false
    self.uncomplete_reason = reason
    self.save(validate: false)
    self.run_distance.destroy if self.run_distance
    TrackerActionLog.uncomplete_run(self, user)
  end
  
  # Returns sum of actual run hours across a collection
  def self.total_actual_hours
    total_hours(actual: true)
  end

  # Returns sum of scheduled run hours across a collection
  def self.total_scheduled_hours
    total_hours(actual: false)
  end

  # Returns the total hours of a collection of runs
  def self.total_hours(opts={actual: true})
    query_str = opts[:actual] ? 'actual_end_time - actual_start_time' : 'scheduled_end_time - scheduled_start_time'
    sum("extract(epoch from (#{query_str}))") / 3600.0
  end

  def duration_in_hours
    actual_start_time && actual_end_time ? hours_operated : hours_scheduled
  end

  # Returns length in hours for an individual run. Use scheduled hours
  def hours_scheduled
    seconds = scheduled_end_time - scheduled_start_time
    seconds / 3600.0
  end

  # Returns length in hours for an individual run. Use scheduled hours
  def hours_operated
    if actual_start_time && actual_end_time
      seconds = actual_end_time - actual_start_time
      seconds / 3600.0
    end
  end

  # sum up number_of_passengers in each tracking type from completed trips
  def number_of_passengers_served(tracking_type)
    field_name = get_trip_tracking_field_name(tracking_type)
    trips.completed.sum(field_name)
  end

  # count one way trips in each tracking type
  def number_of_one_way_trips(tracking_type)
    field_name = get_trip_tracking_field_name(tracking_type)
    trips.where("#{field_name} > 0").count
  end
  
  # checks if a run would be valid if it weren't child run
  def valid_as_daily_run?
    r = self.clone
    r.repeating_run = nil
    r.valid?
  end

  private

  def fix_dates
    d = self.date
    unless d.nil?
      unless scheduled_start_time.nil?
        s = scheduled_start_time
        self.scheduled_start_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_start_time_will_change!
      end
      unless scheduled_end_time.nil?
        s = scheduled_end_time
        self.scheduled_end_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_end_time_will_change!
      end
      unless actual_start_time.nil?
        a = actual_start_time
        self.actual_start_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_start_time_will_change!
      end
      unless actual_end_time.nil?
        a = actual_end_time
        self.actual_end_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_end_time_will_change!
      end
    end
    true
  end
  
  
  ### NAME UNIQUENESS ###
  # Is the name unique by date and provider among daily and repeating runs?
  def name_uniqueness
    return true if date.nil? || name.nil? || provider.nil?
    daily_name_uniqueness
    repeating_name_uniqueness
  end
  
  # determines if any daily runs overlap with this run and have the same name and provider
  def daily_name_uniqueness
    if provider.runs      # same provider
        .for_date(date)     # same date
        .where("lower(name) = ?", name.try(:to_s).downcase)  # same name
        .other_than(self)   # not the same run
        .present?
      errors.add(:name,  "should be unique by day and by provider among daily runs")
    end
  end
  
  # determines if any repeating runs overlap with this run and have the same name and provider
  # skip this validation if the date is within the advance day scheduling window for the provider
  def repeating_name_uniqueness
    return true if provider.scheduler_window_covers?(date)
    if provider.repeating_runs    # same provider
        .where("lower(name) = ?", name.try(:to_s).downcase)          # same name
        .not_the_parent_of(self)    # not the parent repeating run
        .schedule_occurs_on(date)   # repeating run schedule occurs on this run's date
        .present?
      errors.add(:name,  "should be unique by day and by provider among repeating runs")
    end
  end
  ###
  

  ### DRIVER AVAILABILITY ###
  # Validates that the driver is not assigned to any overlapping daily or repeating runs
  def driver_availability
    return true if date.nil? || driver.nil?
    daily_driver_availability
    repeating_driver_availability
  end
  
  def daily_driver_availability
    if Run.other_overlapped_runs(self).pluck(:driver_id).include?(self.driver_id)
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end
  
  def repeating_driver_availability
    return true if provider.scheduler_window_covers?(date)
    if RepeatingRun.where(driver: driver)   # same driver
        .not_the_parent_of(self)            # not the parent repeating run
        .overlaps_with_run(self)            # repeating run schedule occurs on this run's date and time
        .present?
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_overlapping_repeating_run))
    end
  end
  ###


  ### VEHICLE AVAILABILITY ###
  # Validates that the vehicle is not assigned to any overlapping daily or repeating runs
  def vehicle_availability
    return true if date.nil? || vehicle.nil?
    daily_vehicle_availability
    repeating_vehicle_availability
  end
  
  def daily_vehicle_availability
    if Run.other_overlapped_runs(self).pluck(:vehicle_id).include?(self.vehicle.id)
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end
  
  def repeating_vehicle_availability
    return true if provider.scheduler_window_covers?(date)
    if RepeatingRun.where(vehicle: vehicle)   # same vehicle
        .not_the_parent_of(self)              # not the parent repeating run
        .overlaps_with_run(self)              # repeating run schedule occurs on this run's date and time
        .present?
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_overlapping_repeating_run))
    end
  end
  ###
  
  def check_provider_fields_required_for_run_completion
    provider.present? && provider.fields_required_for_run_completion.select{ |attr| self[attr].blank? if FIELDS_FOR_COMPLETION.include?(attr.try(:to_sym)) }.empty?
  end

  def within_advance_day_scheduling
    advance_day_scheduling = provider.try(:get_advance_day_scheduling)
    if date && advance_day_scheduling.present? && (date - Date.current).to_i > advance_day_scheduling
      errors.add(:date, TranslationEngine.translate_text(:beyond_advance_day_scheduling) % {advance_day_scheduling: advance_day_scheduling})
    end
  end

  def get_trip_tracking_field_name(tracking_type)
    if ['senior', 'disabled', 'low_income'].include?(tracking_type.to_s)
      "number_of_#{tracking_type}_passengers_served"
    end
  end
  
  # Returns true if run was generated by a parent repeating run
  def child_run?
    repeating_run.present?
  end

  def check_vehicle_change
    if self.changes.include?(:vehicle_id)
      self.from_garage_address = self.vehicle.try(:garage_address).try(:dup) 
      self.to_garage_address = self.vehicle.try(:garage_address).try(:dup) 
    end

    true
  end

  def check_manifest_change
    if self.changes.include?(:date)
      @unschedule_trips = true
    else
      if (self.changes.keys & ["scheduled_start_time", "scheduled_end_time", "from_garage_address_id", "to_garage_address_id"]).any?
        @clear_manifest_times = true
      end
    end

    true
  end  

  def apply_manifest_changes
    if @unschedule_trips
      # TODO
      self.unschedule!(false)
    elsif @clear_manifest_times
      self.itineraries.clear_times!
      self.itineraries.run_begin.update_all(time: self.scheduled_start_time, address_id: self.from_garage_address.try(:id) || self.vehicle.try(:garage_address).try(:id))
      self.itineraries.run_end.update_all(time: self.scheduled_end_time, address_id: self.to_garage_address.try(:id) || self.vehicle.try(:garage_address).try(:id))
    end

    true
  end
  
end
