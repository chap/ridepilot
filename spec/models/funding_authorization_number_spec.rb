require 'rails_helper'

RSpec.describe FundingAuthorizationNumber, type: :model do
  let(:funding_authorization_number_attrs) { attributes_for(:funding_authorization_number) }
  
  describe "number" do 
    it "required" do 
      funding_number = build(:funding_authorization_number)
      funding_number.number = nil
      expect(funding_number).to be_invalid
    end

    it "maximum length is 20" do 
      funding_number = build(:funding_authorization_number)
      expect(funding_number).to be_valid 
      funding_number.number = '111111111111111111111'
      expect(funding_number).to be_invalid
    end
  end

  it 'parses itself from a hash' do
    funding_number = FundingAuthorizationNumber.new(funding_authorization_number_attrs)
    expect(funding_authorization_number_attrs.all? do |att, val| 
      val == funding_number.send(att)
    end).to be true
  end
end
