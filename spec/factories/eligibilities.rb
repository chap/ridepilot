FactoryGirl.define do
  factory :eligibility do
    sequence(:code)  {|n| "eligibility_#{n}" }
    description "MyString"
  end

end
