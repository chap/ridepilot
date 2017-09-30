require 'active_support/concern'

module TripCore
  extend ActiveSupport::Concern

  included do
    belongs_to :customer, -> { with_deleted }, validate: false
    belongs_to :dropoff_address,  -> { with_deleted }, class_name: "Address"
    belongs_to :funding_source, -> { with_deleted }
    belongs_to :mobility, -> { with_deleted }
    belongs_to :pickup_address, -> { with_deleted }, class_name: "Address"
    belongs_to :provider, -> { with_deleted }
    belongs_to :service_level, -> { with_deleted }
    belongs_to :trip_purpose, -> { with_deleted }


    delegate :name, to: :service_level, prefix: :service_level, allow_nil: true
    delegate :name, to: :customer, prefix: :customer, allow_nil: true
    delegate :name, to: :trip_purpose, prefix: :trip_purpose, allow_nil: true

    validates :attendant_count, numericality: {greater_than_or_equal_to: 0}
    validates :customer, associated: true, presence: true
    validates :dropoff_address, associated: true, presence: true
    validates :guest_count, numericality: {greater_than_or_equal_to: 0}
    validates :pickup_address, associated: true, presence: true
    validates :trip_purpose_id, presence: true
    validates_datetime :pickup_time, presence: true
    validates_datetime :appointment_time, allow_nil: true, on_or_after: :pickup_time, on_or_after_message: "should be no earlier than pickup time"
    validates :mobility_device_accommodations, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }

    accepts_nested_attributes_for :customer

    scope :by_funding_source,  -> (name) { includes(:funding_source).references(:funding_source).where("funding_sources.name = ?", name) }
    scope :by_service_level,   -> (level) { includes(:service_level).references(:service_level).where("service_levels.name = ?", level) }
    scope :by_trip_purpose,    -> (name) { includes(:trip_purpose).references(:trip_purpose).where("trip_purposes.name = ?", name) }
    scope :for_provider,       -> (provider_id) { where(provider_id: provider_id) }
    scope :individual,         -> { joins(:customer).where(customers: {group: false}) }
    scope :not_called_back,    -> { where('called_back_at IS NULL') }
  end

  def trip_size
    if customer.try(:group)
      group_size
    else
      guest_count + attendant_count + 1
    end
  end

  def trip_count
    trip_size
  end

  def is_in_district?
    pickup_address.try(:in_district) && dropoff_address.try(:in_district)
  end

  module ClassMethods
  end
end
