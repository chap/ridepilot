FactoryGirl.define do
  factory :vehicle_maintenance_schedule do
    name { Faker::Lorem.words(2).join(' ') }
    mileage 1
    vehicle_maintenance_schedule_type
  end

end
