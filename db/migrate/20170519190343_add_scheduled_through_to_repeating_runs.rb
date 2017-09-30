class AddScheduledThroughToRepeatingRuns < ActiveRecord::Migration
  def change
    add_column :repeating_runs, :scheduled_through, :date
  end
end
