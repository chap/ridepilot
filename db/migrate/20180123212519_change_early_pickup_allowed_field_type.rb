class ChangeEarlyPickupAllowedFieldType < ActiveRecord::Migration
  def change
    remove_column :trips, :early_pickup_allowed
    add_column :trips, :early_pickup_allowed, :boolean
  end
end
