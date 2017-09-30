class AddCabEnabledToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :cab_enabled, :boolean
  end
end
