class CreateVehicleMaintenanceScheduleTypes < ActiveRecord::Migration
  def change
    create_table :vehicle_maintenance_schedule_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
