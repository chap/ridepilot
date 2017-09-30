FactoryGirl.define do
  factory :funding_authorization_number do
    customer
    number { Faker::Number.number(10)}
    funding_source
    contact_info { Faker::Lorem.words(12).join(' ') }
  end

end
