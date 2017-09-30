require 'rails_helper'

RSpec.describe AddressGroup, type: :model do
  describe ".name" do 
    it "is required" do
      invalid_address_group = build(:address_group, name: nil)
      expect(invalid_address_group).not_to be_valid 

      valid_address_group = build(:address_group)
      expect(valid_address_group).to be_valid 
    end

    it "is case-insentive unique" do
      existing_address_group = create(:address_group)

      invalid_address_group = build(:address_group, name: existing_address_group.name.downcase)
      expect(invalid_address_group).not_to be_valid 
    end
  end
end
