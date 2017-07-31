class VehicleMaintenanceSchedule < ActiveRecord::Base
  belongs_to :vehicle_maintenance_schedule_type
  has_one :document, as: :documentable, dependent: :destroy, inverse_of: :documentable
  accepts_nested_attributes_for :document, allow_destroy: true

  validates :name, presence: true, uniqueness: { 
                    scope: :vehicle_maintenance_schedule_type, 
                    case_sensitive: false,
                    message: 'should be unique within a schedule type' }
  normalize_attribute :name, :with => [ :strip ]

  validates :mileage, presence: true, 
                    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :default_order, -> { order(:mileage, :name) }
end
