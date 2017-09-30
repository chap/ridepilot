class AddAltAddressIdToDrivers < ActiveRecord::Migration
  def change
    add_column :drivers, :alt_address_id, :integer
    add_index :drivers, :alt_address_id
  end
end
