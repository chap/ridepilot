class AddGaragePhoneNumberToVehicle < ActiveRecord::Migration
  def change
    add_column :vehicles, :garage_phone_number, :string
  end
end
