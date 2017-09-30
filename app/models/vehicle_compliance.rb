class VehicleCompliance < ActiveRecord::Base
  include ComplianceCore

  has_paper_trail
  
  belongs_to :vehicle, inverse_of: :vehicle_compliances
  belongs_to :vehicle_requirement_template, -> { with_deleted }
  
  validates :vehicle, presence: true
  
  scope :for_vehicle, -> (vehicle_id) { where(vehicle_id: vehicle_id) }
end
