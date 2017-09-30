class AddScheduledThroughToRepeatingTrips < ActiveRecord::Migration
  def change
    add_column :repeating_trips, :scheduled_through, :date
  end
end
