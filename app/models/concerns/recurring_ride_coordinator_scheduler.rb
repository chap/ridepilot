require 'active_support/concern'

module RecurringRideCoordinatorScheduler
  extend ActiveSupport::Concern
  include ScheduleAttributes
  include ScheduleHelpers # Handles identifying schedule conflicts

  NON_RIDE_COORDINATOR_ATTRIBUTES = %w(
    id recurrence schedule_yaml created_at updated_at lock_version 
    start_date end_date comments scheduled_through pickup_address_notes 
    dropoff_address_notes manifest_order
  )

  included do
  end
  
  def instantiate!
    raise "Must be defined by including model!"
  end
  
  module ClassMethods
    # Create occurrences from all schedulers. This method is idempotent.
    def generate!
      schedulers = self.all 
      schedulers = schedulers.active if schedulers.respond_to?(:active)
      for scheduler in schedulers
        scheduler.instantiate!
      end
    end

    def ride_coordinator_attributes  
      attribute_names - NON_RIDE_COORDINATOR_ATTRIBUTES
    end
  end
end
