class AddInitialMileageChangeReasonToVehicles < ActiveRecord::Migration
  def change
    add_column :vehicles, :initial_mileage_change_reason, :text
  end
end
