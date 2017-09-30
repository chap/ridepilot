class AddInactiveFieldsToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :active, :boolean
    add_column :customers, :inactivated_start_date, :date
    add_column :customers, :inactivated_end_date, :date
    add_column :customers, :active_status_changed_reason, :text
  end
end
