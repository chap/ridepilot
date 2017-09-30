class DriverHistory < ActiveRecord::Base
  include DocumentAssociable
  
  has_paper_trail
  
  belongs_to :driver, inverse_of: :driver_histories

  validates_presence_of :driver, :event
  validates_date :event_date, on_or_before: -> { Date.current }
  
  scope :default_order, -> { order(:event_date) }
  
end
