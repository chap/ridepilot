class AddCustomerNonsharableToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :customer_nonsharable, :boolean, default: false
  end
end
