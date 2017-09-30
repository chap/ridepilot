class AddRepeatingRunToRepeatingTrips < ActiveRecord::Migration
  def change
    add_reference :repeating_trips, :repeating_run, index: true
  end
end
