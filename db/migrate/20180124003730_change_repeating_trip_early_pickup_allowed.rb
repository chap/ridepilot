class ChangeRepeatingTripEarlyPickupAllowed < ActiveRecord::Migration
  def change
    remove_column :repeating_trips, :early_pickup_allowed
    add_column :repeating_trips, :early_pickup_allowed, :boolean
  end
end
