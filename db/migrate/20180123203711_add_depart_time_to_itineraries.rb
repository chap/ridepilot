class AddDepartTimeToItineraries < ActiveRecord::Migration
  def change
    add_column :itineraries, :depart_time, :datetime
    add_column :repeating_itineraries, :depart_time, :datetime
  end
end
