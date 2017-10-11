class VehicleCapacity < Capacity
  belongs_to :vehicle_type, foreign_key: :host_id
end
