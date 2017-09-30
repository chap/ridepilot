class AddInactivatedDateToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :inactivated_date, :datetime
    add_column :providers, :inactivated_reason, :string
  end
end
