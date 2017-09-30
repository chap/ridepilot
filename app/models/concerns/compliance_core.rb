require 'active_support/concern'

module ComplianceCore
  extend ActiveSupport::Concern

  included do
    include DocumentAssociable
    include ComplianceEvent

    validates_date :due_date
    
    scope :legal,      ->  { where(legal: true) }
    scope :non_legal,      ->  { where("legal is NULL or legal = ?", false) }
    scope :overdue, -> (as_of: Date.current) { incomplete.where("due_date < ?", as_of) }
    scope :due_soon, -> (as_of: Date.current, through: nil) { incomplete.where(due_date: as_of..(through || as_of + 6.days)) }
    scope :default_order, -> { order(:due_date) }
  end

end
