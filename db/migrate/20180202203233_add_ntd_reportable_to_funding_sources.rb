class AddNtdReportableToFundingSources < ActiveRecord::Migration
  def change
    add_column :funding_sources, :ntd_reportable, :boolean
    remove_column :trips, :ntd_reportable, :boolean, default: true
    remove_column :repeating_trips, :ntd_reportable, :boolean, default: true
    remove_column :runs, :ntd_reportable, :boolean, default: true
    remove_column :repeating_runs, :ntd_reportable, :boolean, default: true
    remove_column :vehicles, :ntd_reportable, :boolean, default: true
  end
end
