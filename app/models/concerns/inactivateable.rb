require 'active_support/concern'

# Use with `include Inactivateable`
# Owner will be able to configure its availability
module Inactivateable
  extend ActiveSupport::Concern

  included do

    scope :active,          -> { where(active: true) }
    scope :active_for_date, -> (date) { where("active = ? and (inactivated_start_date > ? or inactivated_end_date < ? or (inactivated_end_date is null and inactivated_start_date is null))", true, date, date) }
    
    def inactivated?
      # permanent inactive
      # or, inactive for a date range
      permanent_inactivated? || temporarily_inactivated?
    end

    def permanent_inactivated?
      !active
    end

    def temporarily_inactivated?
      !permanent_inactivated? && (inactivated_start_date.present? || inactivated_end_date.present?)
    end

    def reactivate!
      self.active = true
      self.inactivated_start_date = nil
      self.inactivated_end_date = nil
      self.active_status_changed_reason = nil
      self.save(validate: false)
    end

    def active_for_date?(date)
      active && (
        (!inactivated_start_date && !inactivated_end_date) ||
        (inactivated_start_date && inactivated_start_date > date) ||
        (inactivated_end_date && inactivated_end_date < date)
      )
    end

    def active_status_text
      if !inactivated?
        "active"
      elsif permanent_inactivated?
        "permanently out of service"
      elsif temporarily_inactivated?
        if inactivated_end_date.present? 
          if inactivated_end_date >= Date.today
            "temporarily inactive from #{inactivated_start_date.try(:strftime, '%m/%d/%Y')} to #{inactivated_end_date.try(:strftime, '%m/%d/%Y')}" 
          else
            "active"
          end
        else
          "temporarily inactive from #{inactivated_start_date.try(:strftime, '%m/%d/%Y')}"
        end
      end
    end
  end
end


