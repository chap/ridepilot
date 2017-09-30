FactoryGirl.define do
  factory :repeating_trip do
    association :pickup_address, factory: :address
    association :dropoff_address, factory: :address
    pickup_time { Time.now + 1.week }
    appointment_time { pickup_time + 30.minutes }
    provider
    customer
    trip_purpose
  end
end
