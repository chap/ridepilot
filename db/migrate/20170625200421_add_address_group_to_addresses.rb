class AddAddressGroupToAddresses < ActiveRecord::Migration
  def change
    add_reference :addresses, :address_group, index: true
  end
end
