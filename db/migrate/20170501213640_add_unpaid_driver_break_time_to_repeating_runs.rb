class AddUnpaidDriverBreakTimeToRepeatingRuns < ActiveRecord::Migration
  def change
    add_column :repeating_runs, :unpaid_driver_break_time, :integer
  end
end
