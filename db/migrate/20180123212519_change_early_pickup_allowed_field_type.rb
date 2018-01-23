class ChangeEarlyPickupAllowedFieldType < ActiveRecord::Migration
  def up
    remove_column :trips, :early_pickup_allowed
    add_column :trips, :early_pickup_allowed, :boolean
  end
end
