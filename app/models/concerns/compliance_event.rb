require 'active_support/concern'

module ComplianceEvent
  extend ActiveSupport::Concern

  included do
    validates :event, presence: true
    validates_date :compliance_date, on_or_before: -> { Date.current }, allow_blank: true

    scope :incomplete, -> { where(compliance_date: nil) }
    scope :complete, -> { where.not(compliance_date: nil) }
  end
  
  def complete?
    compliance_date.present?
  end
  
  def overdue?(as_of: Date.current)
    if as_of.is_a? Range
      as_of.include? due_date
    else
      as_of > due_date
    end
  end  
end
