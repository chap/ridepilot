require 'faker'

FactoryGirl.define do
  factory :customer do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    provider
    
    trait :with_travel_trainings do
      after(:create) do |customer|
        3.times { create(:travel_training, customer: customer) }
      end
    end

    trait :with_funding_authorization_numbers do
      after(:create) do |customer|
        3.times { create(:funding_authorization_number, customer: customer) }
      end
    end
  end
end
