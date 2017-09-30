class AddReoccuringToDriverRequirementTemplates < ActiveRecord::Migration
  def change
    add_column :driver_requirement_templates, :reoccuring, :boolean
  end
end
