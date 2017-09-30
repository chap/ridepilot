class AddAdvanceDaySchedulingToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :advance_day_scheduling, :integer
  end
end
