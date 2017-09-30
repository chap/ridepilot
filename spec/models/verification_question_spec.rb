require 'rails_helper'

RSpec.describe VerificationQuestion, type: :model do
  
  let(:question) { create(:verification_question) }
  
  it 'should have a question, answer, and associated user' do
    expect(question).to respond_to(:question)
    expect(question).to respond_to(:answer)
    expect(question).to respond_to(:user)
  end
  
  it 'should identify correct and incorrect answers' do
    correct_answer_exact = question.answer
    correct_answer_diff_formatting = "   " + question.answer.upcase + " "
    incorrect_answer = question.answer.reverse + "X"
    
    expect(question.correct?(correct_answer_exact)).to be true
    expect(question.correct?(correct_answer_diff_formatting)).to be true
    expect(question.correct?(incorrect_answer)).to be false
  end
  
end
