class CustomerEligibility < ActiveRecord::Base
  belongs_to :customer, -> { with_deleted }
  belongs_to :eligibility

  validates :customer, presence: true
  validates :eligibility, presence: true

  scope :specified,   -> { where.not(eligible: nil) }
  scope :eligible,    -> { where(eligible: true) }
  scope :ineligible,  -> { where(eligible: false) }

  def as_json
    {
      description: eligibility.description,
      code: eligibility.code,
      eligible: eligible
    }
  end
end
