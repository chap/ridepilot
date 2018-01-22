class AddNtdStatsToRunDistance < ActiveRecord::Migration
  def change
    add_column :run_distances, :ntd_total_miles, :float
    add_column :run_distances, :ntd_total_revenue_miles, :float
    add_column :run_distances, :ntd_total_passenger_miles, :float
    add_column :run_distances, :ntd_total_hours, :float
    add_column :run_distances, :ntd_total_revenue_hours, :float
  end
end
