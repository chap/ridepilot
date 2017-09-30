class AddAdaIneligibleReasonToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :ada_ineligible_reason, :text
  end
end
