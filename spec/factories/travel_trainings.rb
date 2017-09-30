FactoryGirl.define do
  factory :travel_training do
    customer
    date { DateTime.current }
    comment { Faker::Lorem.words(12).join(' ') }
  end

end
