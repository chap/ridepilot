FactoryGirl.define do
  factory :address_group do
    name { Faker::Lorem.words(2).join(' ') }
  end

end
