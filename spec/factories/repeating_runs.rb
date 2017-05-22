FactoryGirl.define do
  factory :repeating_run do
    name { Faker::Lorem.words(2).join(' ') }
    vehicle
    driver
    provider
    
    # SCHEDULE ATTRS
    start_date { Date.today } # Set the schedule start date to equal date field
    repetition_interval 1   # Setting this messes up the recurring_ride_coordinator shared examples 
    repeats_mondays { start_date.monday? }
    repeats_tuesdays { start_date.tuesday? }
    repeats_wednesdays { start_date.wednesday? }
    repeats_thursdays { start_date.thursday? }
    repeats_fridays { start_date.friday? }
    repeats_saturdays { start_date.saturday? }
    repeats_sundays { start_date.sunday? }

    factory :repeating_run_with_schedule do

      trait :no_repeating_days do
        repeats_mondays nil
        repeats_tuesdays nil
        repeats_wednesdays nil
        repeats_thursdays nil
        repeats_fridays nil
        repeats_saturdays nil
        repeats_sundays nil
      end
      
      trait :weekly do
        repetition_interval 1
      end
      
      trait :biweekly do
        repetition_interval 2
      end
      
      trait :triweekly do
        repetition_interval 3
      end
      
      trait :last_week do
        start_date { Date.today - 1.week }
      end

      trait :two_days_ago do
        start_date { Date.today - 2.days }
      end

      trait :yesterday do
        start_date { Date.yesterday }
      end

      trait :today do
        start_date { Date.today }
      end

      trait :tomorrow do
        start_date { Date.tomorrow }
      end

      trait :next_week do
        start_date { Date.today + 1.week }
      end
    end
  end

  
end
