class AddLegalToDriverCompliance < ActiveRecord::Migration
  def change
    add_column :driver_compliances, :legal, :boolean
  end
end
