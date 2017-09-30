class AddDeletedAtToDriverRequirementTemplates < ActiveRecord::Migration
  def change
    add_column :driver_requirement_templates, :deleted_at, :datetime
  end
end
