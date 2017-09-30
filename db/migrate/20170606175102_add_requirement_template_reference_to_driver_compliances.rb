class AddRequirementTemplateReferenceToDriverCompliances < ActiveRecord::Migration
  def change
    add_reference :driver_compliances, :driver_requirement_template, index: true
  end
end
