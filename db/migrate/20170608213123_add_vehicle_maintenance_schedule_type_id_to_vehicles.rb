class AddVehicleMaintenanceScheduleTypeIdToVehicles < ActiveRecord::Migration
  def change
    add_column :vehicles, :vehicle_maintenance_schedule_type_id, :integer
    add_index :vehicles, :vehicle_maintenance_schedule_type_id, name: 'index_veh_maint_sched_type_id'
  end
end
