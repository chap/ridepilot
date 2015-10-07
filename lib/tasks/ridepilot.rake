require 'securerandom'
  
namespace :ridepilot do

  #------------- Incremental Seeding ------------------
  desc 'Seed default lookup tables and configurations'
  task :seed_lookup_tables => :environment do
    puts 'trip purposes...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_purposes.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip purposes'

    puts 'trip results...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_results.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip results'

    puts 'service levels...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_service_levels.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding service levels'

    puts 'mobilities...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_mobilities.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding mobilities'

    puts 'lookup table configurations...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_lookup_table_configurations.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding lookup table configurations'
  end

  desc 'Seed list of supporting custom reports'
  task :seed_custom_reports => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_custom_reports.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding supporting custom reports'
  end

  desc 'Seed list of eligibility factors'
  task :seed_eligibilities => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_eligibilities.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding eligibilities'
  end

  desc 'Seed some fake data for testing'
  task :seed_test_data => :environment do

    for index in 1..5
      customer = Customer.new
      customer.first_name = "Customer_first_name_#{index}"
      customer.last_name = "Customer_last_name_#{index}"
      customer.address = Address.first
      customer.provider = Provider.first
      puts customer.save!
    end
    for index in 1..5
      provider = Provider.find_or_create_by(:name => "provider_name_#{index}")
      puts provider.save!
    end
    for index in 1..5
      #assign to a random provider
      offset = rand(Provider.count)
      random_provider = Provider.offset(offset).first
      provider_id = 
      user = User.find_or_create_by(:email => "abromley#{index}@camsys.com")
      user.password = "welcome1!"
      user.current_provider_id = random_provider.id
      user.save!
      role = Role.new
      role.user_id = user.id
      role.provider_id = random_provider.id
      role.level = 100
      puts role.save!
    end
  end

  desc "Seed supported filter types in reporting engine "
  task seed_reporting_filter_types: :environment do

    %w(
      eq not_eq 
      matches does_not_match 
      lt gt 
      lteq gteq 
      in not_in 
      cont not_cont 
      cont_any not_cont_any 
      i_cont i_not_cont
      start not_start
      end not_end
      true not_true
      false not_false
      present blank
      null not_null
      range
      select
      multi_select
      ).each do |type|
      Reporting::FilterType.where(name: type).first_or_create
    end
    puts 'Finished seeding reporting filter types.'

  end # task

  desc "mark addresses if associated with a driver"
  task mark_address_if_driver_associated: :environment do
    Driver.includes(:address).each do |driver|
      driver.address.update_attributes(is_driver_associated: true) if driver.address
    end
  end

  desc "Generate customer token"
  task generate_customer_token: :environment do
    Customer.where(token: nil).each do |customer|
      customer.update_attribute(:token, SecureRandom.uuid)
    end
  end
  #------------- End of Incremental Seeding --------------
end
