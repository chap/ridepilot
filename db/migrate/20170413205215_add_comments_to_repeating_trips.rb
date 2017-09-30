class AddCommentsToRepeatingTrips < ActiveRecord::Migration
  def change
    add_column :repeating_trips, :comments, :string
  end
end
