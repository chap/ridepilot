class AddIsUserAssociatedToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :is_user_associated, :boolean
  end
end
