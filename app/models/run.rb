class Run < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include RunCore
  include PublicActivity::Common

  acts_as_paranoid # soft delete

  has_paper_trail

  # Ignores:
  #   Already required:
  #     date
  #     driver_id
  #     provider_id
  #     vehicle_id
  #   Already checked by set_complete:
  #     start_odometer
  #     end_odometer 
  #   Meta
  #     created_at
  #     updated_at
  #     lock_version
  FIELDS_FOR_COMPLETION = [
    :unpaid_driver_break_time,
    :paid,
  ].freeze
  
  BATCH_ACTIONS = [
    :cancel,
    :delete
  ].freeze

  has_many :trips, -> { order(:pickup_time) }, :dependent => :nullify
  belongs_to :repeating_run

  accepts_nested_attributes_for :trips

  before_validation :fix_dates, :set_complete

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

  scope :other_overlapped_runs, -> (run) { overlapped(run).other_than(run) }

  CAB_RUN_ID = -1 # id for cab runs
  UNSCHEDULED_RUN_ID = -2 # id for unscheduled run (empty container)
  
  # "Cancels" a run: removes any trips from that run
  def cancel
    trips.delete_all # Doesn't actually destroy the records, just removes the association
  end
  
  # Cancels all runs in the collection, returning the count of trips removed from runs
  def self.cancel_all
    Trip.where(run_id: self.all.pluck(:id)).update_all(run_id: nil)
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

  def self.fake_cab_run
    Run.new name: TranslationEngine.translate_text(:cab), id: Run::CAB_RUN_ID
  end

  def self.fake_unscheduled_run
    Run.new name: TranslationEngine.translate_text(:unscheduled), id: Run::UNSCHEDULED_RUN_ID
  end

  def self.update_prior_run_complete_status!
    
    Run.where(provider_id: Provider.active.pluck(:id)).prior_to(Date.today).incomplete.each do |r|
      completed = r.check_complete_status
      r.update(complete: true) if completed
    end
  end

  def check_complete_status
    start_odometer.present? && end_odometer.present? && start_odometer < end_odometer && trips.incomplete.empty? && check_provider_fields_required_for_run_completion
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
    query_result = sum(query_str).to_s.to_time
    return query_result ? query_result.seconds_since_midnight / 3600.0 : 0
  end

  # Returns length in hours for an individual run. Use scheduled hours
  def hours_scheduled
    seconds = scheduled_end_time - scheduled_start_time
    seconds / 3600.0
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

  # A run is considered complete if:
  #  actual_end_time is valued (which requires that actual_start_time is also valued)
  #  actual_end_time is before "now"
  #  None of its trips are still considered pending
  #  Any fields that the run provider has listed as required are valued
  def set_complete
    self.complete = self.check_complete_status
    true
  end

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
    if Run.other_overlapped_runs(self).pluck(:driver_id).include?(self.driver.id)
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
  
end
