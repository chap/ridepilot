class CreateVerificationQuestions < ActiveRecord::Migration
  def change
    create_table :verification_questions do |t|
      t.references :user, index: true
      t.text :question
      t.text :answer
      
      t.timestamps
    end
  end
end
