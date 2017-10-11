class RenameVehicleCapacities < ActiveRecord::Migration
  def change
    rename_table :vehicle_capacities, :capacities
    rename_column :capacities, :vehicle_type_id, :host_id
    add_column :capacities, :type, :string
  end
end
