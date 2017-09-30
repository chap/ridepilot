# This is added to run scheduler on heroku
# Heroku_scheduler requires a rake task
# This is also called by WHenever gem to schedule
namespace :scheduler do

  task run: :environment do
    # Schedule repeating runs 
    #    Important: Execute this before creating repeating trips so can 
    #    assign a trip instance to an existing repeating run instance 
    RepeatingRun.active.generate!

    # Schedule repeating trips
    RepeatingTrip.active.generate!

    # Update run status
    Run.update_prior_run_complete_status!

    # Standby -> Unmet Need
    #Trip.move_prior_standby_to_unmet!

  end
end