class TripResult < ActiveRecord::Base
  acts_as_paranoid # soft delete
  has_paper_trail

  SHOW_ALL_ID = -2
  UNSCHEDULED_ID = -1

  # Cancelled, Late Cancel, Same Day Cancel, Missed Trip, No Show
  CANCEL_CODES = ['CANC', 'LTCANC', 'SDCANC', 'MT', 'NS']
  NON_DISPATCHABLE_CODES = CANCEL_CODES + ['UNMET', 'TD']
  CODES_NEED_REASON = CANCEL_CODES + ['TD']

  validates_presence_of :name, :code
  scope :cancel_codes, -> { where(code: CANCEL_CODES) }

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids)
  end

  def full_description
    description || name
  end

  def self.is_reason_needed?(code)
    CODES_NEED_REASON.include? code
  end

  def self.is_cancel_code?(code)
    CANCEL_CODES.include? code
  end

  def turned_down?
    code == 'TD'
  end

  def cancelled?
    self.class.is_cancel_code?(code)
  end

  def self.non_dispatchable_result_ids
    @non_dispatchable_result_ids ||= where(code: NON_DISPATCHABLE_CODES).pluck(:id)
  end

  def self.reason_needed_result_ids
    @reason_needed_result_ids ||= where(code: CODES_NEED_REASON).pluck(:id)
  end
end
