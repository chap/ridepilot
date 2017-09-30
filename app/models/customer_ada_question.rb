class CustomerAdaQuestion < ActiveRecord::Base
  belongs_to :customer, -> { with_deleted }
  belongs_to :ada_question

  validates :customer, presence: true
  validates :ada_question, presence: true

  scope :specified,   -> { where.not(answer: nil) }
  scope :eligible,    -> { where(answer: true) }
  scope :ineligible,  -> { where(answer: false) }

  def as_json
    {
      description: ada_question.try(:name),
      eligible: answer
    }
  end
end
