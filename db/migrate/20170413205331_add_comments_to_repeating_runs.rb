class AddCommentsToRepeatingRuns < ActiveRecord::Migration
  def change
    add_column :repeating_runs, :comments, :string
  end
end
