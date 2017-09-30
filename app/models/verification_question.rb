class VerificationQuestion < ActiveRecord::Base
  
  belongs_to :user
  
  # Returns true/false if the answer given matches the stored answer
  def correct?(guess)
    prep_for_comparison(guess) == prep_for_comparison(answer)
  end
  
  # Parses a new Verification Question from a hash
  def self.parse(verification_question_hash, user)
    VerificationQuestion.new({
      question: verification_question_hash[:question],
      answer: verification_question_hash[:answer],
      user: user
    })
  end
  
  protected

  # Converts to lower case and removes whitespace for comparison  
  def prep_for_comparison(string)
    string.downcase.gsub(/\s+/, '')
  end
  
end
