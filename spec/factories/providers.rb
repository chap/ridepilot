require 'faker'

FactoryGirl.define do
  factory :provider do
    sequence(:name) {|n| "sample_provider_#{n}" }
    advance_day_scheduling 21
    cab_enabled true
  end
end
