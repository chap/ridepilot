FactoryGirl.define do
  factory :emergency_contact do
    name "MyString"
    geocoded_address
    driver
    phone_number "888-345-6789"
    relationship "MyString"
  end

end
