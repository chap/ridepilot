class AddDeletedAtToEmergencyContact < ActiveRecord::Migration
  def change
    add_column :emergency_contacts, :deleted_at, :datetime
  end
end
