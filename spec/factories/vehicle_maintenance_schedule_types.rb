FactoryGirl.define do
  factory :vehicle_maintenance_schedule_type do
    name { Faker::Lorem.words(2).join(' ') }
    provider
  end

end
