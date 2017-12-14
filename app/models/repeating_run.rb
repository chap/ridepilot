# This is a 'dumb' model. It is managed by a Run instance, which creates a 
# repeating instance of itself when instructed to. Validation is nonexistent 
# since all data should already have been vetted by the Run instance.
class RepeatingRun < ActiveRecord::Base
  include RunCore
  include RequiredFieldValidatorModule
  include RecurringRideCoordinator
  include RecurringRideCoordinatorScheduler
  include PublicActivity::Common

  has_paper_trail

  has_many :repeating_trips, through: :weekday_assignments
  has_many :weekday_assignments, dependent: :destroy

  has_many :repeating_run_manifest_orders, dependent: :destroy

  validates :comments, :length => { :maximum => 30 }
  validate :name_uniqueness
  normalize_attribute :name, :with => [ :strip ]
  
  validate :driver_availability
  validate :vehicle_availability
  
  has_many :runs # Child runs created by this RepeatingRun's scheduler

  scope :active, -> { where("end_date is NULL or end_date >= ?", Date.today) }
  # a query to find repeating_runs that can be used to assign repeating_trips
  scope :during, -> (from_time, to_time) { where("NOT (scheduled_start_time::time <= ?) OR NOT(scheduled_end_time::time <= ?)", to_time.utc.to_s(:time), from_time.utc.to_s(:time)) }
  
  # Repeating Runs where schedule conflicts with another Repeating Run's schedule by DATE
  scope :conflicts_with_schedule, -> (repeating_run) do
    where.not(id: repeating_run.id) # not the same record
    .select { |rr| repeating_run.schedule_conflicts_with?(rr) } # checks for overlap between recurrence rules
  end
  
  # Repeating Runs where schedule covers a given DATE
  scope :schedule_occurs_on, -> (date) do
    select do |rr| 
      rr.date_in_active_range?(date) &&         # date is in schedule's active range 
      rr.schedule.occurs_on?(date)              # schedule occurs on this date
    end
  end
  
  # Repeating Runs where the schedule time overlaps with a daily run by both DATE and TIME
  scope :overlaps_with_run, -> (run) do
    time_overlaps_with(run.scheduled_start_time, run.scheduled_end_time)
    .schedule_occurs_on(run.date)
  end
  
  # Not the parent repeating run of the passed daily run
  scope :not_the_parent_of, -> (daily_run) { where.not(id: daily_run.repeating_run_id) }

  schedules_occurrences_with with_attributes: -> (run) {
      {
        repeat:        1,
        interval_unit: "week",
        start_date:    (run.start_date.try(:to_date) || Date.today).to_s,
        interval:      run.repetition_interval, 
        monday:        run.repeats_mondays    ? 1 : 0,
        tuesday:       run.repeats_tuesdays   ? 1 : 0,
        wednesday:     run.repeats_wednesdays ? 1 : 0,
        thursday:      run.repeats_thursdays  ? 1 : 0,
        friday:        run.repeats_fridays    ? 1 : 0,
        saturday:      run.repeats_saturdays  ? 1 : 0,
        sunday:        run.repeats_sundays    ? 1 : 0
      }
    },
    destroy_future_occurrences_with: -> (run) {
      # Be sure not delete occurrences that have already been completed.
      runs = if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after_today.incomplete
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after(run.date).incomplete
      end

      schedule = run.repeating_run.schedule
      Run.transaction do
        runs.find_each do |r|
          r.destroy unless schedule.occurs_on?(r.date)
        end
      end
    },
    destroy_all_future_occurrences_with: -> (run) {
      # Be sure not delete occurrences that have already been completed.
      runs = if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after_today.incomplete
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after(run.date).incomplete
      end

      runs.destroy_all
    },
    unlink_past_occurrences_with: -> (run) {
      if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).today_and_prior.update_all "repeating_run_id = NULL"
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).prior_to(run.date).update_all "repeating_run_id = NULL"
      end
    }

  # Builds runs based on the repeating run schedule
  def instantiate!
    return unless provider.try(:active?) && active? # Only build runs for active schedules

    # First and last days to create new runs
    now, later = scheduler_window_start, scheduler_window_end
        
    # Transaction block ensures that no DB changes will be made if there are any errors
    RepeatingRun.transaction do
      # Potentially create a run for each schedule occurrence in the scheduler window
      for date in schedule.occurrences_between(now, later)
                
        # Skip if occurrence is outside of schedule's active window
        next unless date_in_active_range?(date.to_date)
                
        # Build a run belonging to the repeating run for each schedule 
        # occurrence that doesn't already have a run built for it.
        unless self.runs.for_date(date).exists?
          run = Run.new(
            self.attributes
              .select{ |k, v| RepeatingRun.ride_coordinator_attributes.include?(k.to_s) }
              .merge( {
                "repeating_run_id" => id,
                "date" => date
              } )
          )
          
          run.save(validate: false) #allow invalid run exist

          TrackerActionLog.create_run(run, nil)
        end
                
      end
      
      # Timestamp the scheduler to its current timestamp or the end of the
      # advance scheduling period, whichever comes last
      self.update_column :scheduled_through, [self.scheduled_through, later].compact.max
    end
  end

  def active?
    active = true

    today = Date.today
    active = false if end_date && today > end_date

    active
  end

  def add_trip_manifest!(trip_id, wday)
    manifest = self.repeating_run_manifest_orders.for_wday(wday).first
    if manifest && !manifest.manifest_order.blank? 
      # remove it first in case same trip was left over
      delete_trip_manifest!(trip_id, wday)

      #scan from the beginning to injert based on scheduled_pickup_time
      unless manifest.manifest_order.blank?
        trip = RepeatingTrip.find_by_id trip_id
        if trip
          trip_pickup_time = trip.pickup_time
          trip_appt_time = trip.appointment_time
          pickup_index = nil 
          appt_index = nil

          manifest.manifest_order.each_with_index do |leg_name, index|
            leg_name_parts = leg_name.split('_')
            leg_trip_id = leg_name_parts[1]
            is_pickup = leg_name_parts[3] == '1'
            a_trip = RepeatingTrip.find_by_id leg_trip_id
            if a_trip 
              action_time = is_pickup ? a_trip.pickup_time : a_trip.appointment_time
              next unless action_time

              pickup_index = index if action_time > trip_pickup_time

              if trip_appt_time
                appt_index = index if action_time > trip_appt_time
              else
                appt_index = pickup_index + 1 if pickup_index
              end

              break if pickup_index && appt_index
            end
          end
          
          unless pickup_index
            pickup_index = manifest_order.size 
            appt_index = pickup_index + 1
          end

          # Injert at certain index
          manifest.manifest_order.insert pickup_index, "trip_#{trip_id}_leg_1" if pickup_index && pickup_index <= manifest.manifest_order.size
          manifest.manifest_order.insert appt_index, "trip_#{trip_id}_leg_2" if appt_index && appt_index <= manifest.manifest_order.size
          manifest.save(validate: false)
        end
      end
    end
  end

  def delete_trip_manifest!(trip_id, wday)
    manifest = self.repeating_run_manifest_orders.for_wday(wday).first
    manifest.delete_trip_manifest(trip_id) if manifest
  end
  
  private
  
  ### NAME UNIQUENESS ###
  # Is the name unique by date and provider among daily and repeating runs?
  def name_uniqueness
    daily_name_uniqueness
    repeating_name_uniqueness
  end
  
  # Determines if any daily runs overlap with this run and have the same name and provider
  def daily_name_uniqueness
    if provider.runs                      # same provider
        .where("lower(name) = ?", name.try(:to_s).downcase)  # same name
        .conflicts_with_schedule(self)    # schedule covers the run's date
        .present?
      errors.add(:name,  "should be unique by day and by provider among daily runs")
    end
  end

  # Determines if the schedule of this repeating run conflicts with the schedule
  # of any other repeating run with the same provider and name
  def repeating_name_uniqueness
    if provider.repeating_runs          # same provider
        .where("lower(name) = ?", name.try(:to_s).downcase)  # same name
        .conflicts_with_schedule(self)  # conflicting schedule
        .present?
      errors.add(:name,  "should be unique by day and by provider among repeating runs")
    end
  end
  ###
  
  
  ### DRIVER AVAILABILITY ###
  # Validates that the driver is not assigned to any overlapping daily or repeating runs
  def driver_availability
    return true if driver.nil?
    daily_driver_availability
    repeating_driver_availability
  end
  
  def daily_driver_availability
    if Run.where(driver: driver)            # same driver
        .overlaps_with_repeating_run(self)  # run overlaps by date and time
        .present?
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end
  
  def repeating_driver_availability
    if RepeatingRun.where(driver: driver)   # same driver
        .overlaps_with_repeating_run(self)  # schedules overlap by date and time
        .present?
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_overlapping_repeating_run))
    end
  end
  ###
  
  
  ### VEHICLE AVAILABILITY ###
  # Validates that the vehicle is not assigned to any overlapping daily or repeating runs
  def vehicle_availability
    return true if vehicle.nil?
    daily_vehicle_availability
    repeating_vehicle_availability
  end
  
  def daily_vehicle_availability
    if Run.where(vehicle: vehicle)            # same vehicle
        .overlaps_with_repeating_run(self)    # run overlaps by date and time
        .present?
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end
  
  def repeating_vehicle_availability
    if RepeatingRun.where(vehicle: vehicle)   # same vehicle
        .overlaps_with_repeating_run(self)    # schedules overlap by date and time
        .present?
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_overlapping_repeating_run))
    end
  end
  ###
  
end
