class AddAltPhoneNumberToDrivers < ActiveRecord::Migration
  def change
    add_column :drivers, :alt_phone_number, :string
  end
end
