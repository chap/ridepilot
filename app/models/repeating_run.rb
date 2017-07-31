# This is a 'dumb' model. It is managed by a Run instance, which creates a 
# repeating instance of itself when instructed to. Validation is nonexistent 
# since all data should already have been vetted by the Run instance.
class RepeatingRun < ActiveRecord::Base
  include RunCore
  include RequiredFieldValidatorModule
  include RecurringRideCoordinator
  include RecurringRideCoordinatorScheduler
  include PublicActivity::Common

  serialize :manifest_order, Array

  has_paper_trail

  validates :comments, :length => { :maximum => 30 }
  validate :name_uniqueness
  normalize_attribute :name, :with => [ :strip ]
  
  validate :driver_availability
  validate :vehicle_availability
  validate :repeating_schedule_day_present
  
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
  
  
  # At least one day of the week must be checked to create a repeating run
  def repeating_schedule_day_present
    unless Date::DAYNAMES.any? {|d| self.send("repeats_#{d.downcase}s").present? }
      errors.add(:schedule_attributes,  "must have at least one day of the week checked for repeating schedule")
    end
  end
  
  
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
