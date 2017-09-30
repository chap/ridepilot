class TravelTraining < ActiveRecord::Base
  
  belongs_to :customer, inverse_of: :travel_trainings
  
  def self.parse(travel_training_hash, customer)
    utility = Utility.new
    TravelTraining.new({
      date: utility.parse_date(travel_training_hash[:date]),
      comment: travel_training_hash[:comment],
      customer: customer
    })
  end
  
end
