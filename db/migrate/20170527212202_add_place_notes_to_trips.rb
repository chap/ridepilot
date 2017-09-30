class AddPlaceNotesToTrips < ActiveRecord::Migration
  def change
    add_column :trips, :pickup_address_notes, :string
    add_column :trips, :dropoff_address_notes, :string
  end
end
