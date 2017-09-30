class AddRunTrackingToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :run_tracking, :boolean
  end
end
