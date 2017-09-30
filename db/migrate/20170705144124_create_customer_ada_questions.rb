class CreateCustomerAdaQuestions < ActiveRecord::Migration
  def change
    create_table :customer_ada_questions do |t|
      t.references :customer, index: true
      t.references :ada_question, index: true
      t.boolean :answer

      t.timestamps
    end
  end
end
