class AddProviderIdToFundingSources < ActiveRecord::Migration
  def change
    add_reference :funding_sources, :provider, index: true
  end
end
