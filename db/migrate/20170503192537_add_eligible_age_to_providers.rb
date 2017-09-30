class AddEligibleAgeToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :eligible_age, :integer
  end
end
