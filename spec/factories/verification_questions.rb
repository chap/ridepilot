FactoryGirl.define do
  factory :verification_question do
    question { Faker::Lorem.words(5).join(' ') + '?' }
    answer { Faker::Lorem.words(2).join(' ') }
    user
  end

end
