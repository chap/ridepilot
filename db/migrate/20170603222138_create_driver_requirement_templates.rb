class CreateDriverRequirementTemplates < ActiveRecord::Migration
  def change
    create_table :driver_requirement_templates do |t|
      t.references :provider, index: true
      t.string :name
      t.boolean :legal

      t.timestamps
    end
  end
end
