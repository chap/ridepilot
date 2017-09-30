require 'rails_helper'

RSpec.describe TravelTraining, type: :model do
  let(:travel_training_attrs) { attributes_for(:travel_training) }
  
  it 'parses itself from a hash' do
    travel_training = TravelTraining.new(travel_training_attrs)
    expect(travel_training_attrs.all? do |att, val| 
      val == travel_training.send(att)
    end).to be true
  end
end
