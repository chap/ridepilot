class AddDateRangeToRepeatingRuns < ActiveRecord::Migration
  def change
    add_column :repeating_runs, :start_date, :date
    add_column :repeating_runs, :end_date, :date
  end
end
