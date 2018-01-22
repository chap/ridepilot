class AddWdayToRepeatingItinerary < ActiveRecord::Migration
  def change
    add_column :repeating_itineraries, :wday, :integer
  end
end
