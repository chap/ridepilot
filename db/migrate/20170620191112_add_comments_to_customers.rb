class AddCommentsToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :comments, :text
  end
end
