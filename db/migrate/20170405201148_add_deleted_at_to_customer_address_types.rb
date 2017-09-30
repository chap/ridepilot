class AddDeletedAtToCustomerAddressTypes < ActiveRecord::Migration
  def change
    add_column :customer_address_types, :deleted_at, :datetime
  end
end
