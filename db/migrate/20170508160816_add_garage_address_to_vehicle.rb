class AddGarageAddressToVehicle < ActiveRecord::Migration
  def change
    add_column :vehicles, :garage_address_id, :integer
    add_index :vehicles, :garage_address_id
  end
end
