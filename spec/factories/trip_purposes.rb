FactoryGirl.define do
  factory :trip_purpose do
    sequence(:name) {|n| "sample_purpose_#{n}" }
  end

end
