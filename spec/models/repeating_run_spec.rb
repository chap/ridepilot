require 'rails_helper'

RSpec.describe RepeatingRun, type: :model do
  it_behaves_like "a recurring ride coordinator scheduler"
    
  describe "#instantiate!" do
    # TODO Add some robust examples
    # Partially exercised by recurring_ride_coordinator_shared_examples.rb
    it "generates runs"
  end

  it_behaves_like "a recurring ride coordinator" do
    before do
      @scheduled_instance_class = Run 
      
      # To help us know what attribute to check occurrence dates against
      @occurrence_date_attribute = :date
      @scheduler_date_attribute = :start_date
    end
  end
  
  describe 'validations' do
    
    # Set some context...
    let(:provider_a) { create(:provider) }
    let(:provider_b) { create(:provider) }
    let!(:run_a) { create(:run, :tomorrow, :scheduled_morning, name: "Run A", provider: provider_a) }
    let!(:repeating_run_c) { create(:repeating_run, :biweekly, :tomorrow, :scheduled_morning, name: "Run C", provider: provider_a) }
    
    it 'validates name uniqueness among daily runs by date and provider' do
      valid_run_diff_name = build(:repeating_run, :weekly, :tomorrow, name: "Run B", provider: provider_a)
      valid_run_diff_provider = build(:repeating_run, :weekly, :tomorrow, name: "Run A", provider: provider_b)
      valid_run_diff_date = build(:repeating_run, :weekly, :next_week, name: "Run A", provider: provider_a)
      invalid_run_same_date = build(:repeating_run, :weekly, :tomorrow, name: "Run A", provider: provider_a)
      valid_run_zipper = build(:repeating_run, :biweekly, 
                                start_date: Date.tomorrow - 1.week, 
                                name: "Run A", provider: provider_a)
      invalid_run_collision = build(:repeating_run, :weekly, 
                                start_date: Date.tomorrow - 1.week, 
                                name: "Run A", provider: provider_a)
      
      expect(valid_run_diff_name.valid?).to be true
      expect(valid_run_diff_provider.valid?).to be true
      expect(valid_run_diff_date.valid?).to be true
      expect(invalid_run_same_date.valid?).to be false
      expect(valid_run_zipper.valid?).to be true
      expect(invalid_run_collision.valid?).to be false      
    end
    
    it 'validates name uniqueness among repeating runs by date and provider' do
      valid_run_diff_name     = build(:repeating_run, :weekly, :tomorrow, name: "Run D", provider: provider_a)
      valid_run_diff_provider = build(:repeating_run, :weekly, :tomorrow, name: "Run C", provider: provider_b)
      valid_run_diff_date     = build(:repeating_run, :weekly, :next_week, name: "Run C", provider: provider_a)
      invalid_run_same_date   = build(:repeating_run, :weekly, :tomorrow, name: "Run C", provider: provider_a)
      valid_run_zipper        = build(:repeating_run, :biweekly, 
                                  start_date: Date.tomorrow - 1.week, 
                                  name: "Run C", provider: provider_a)
      invalid_run_collision   = build(:repeating_run, :triweekly, 
                                  start_date: Date.tomorrow - 1.week, 
                                  name: "Run C", provider: provider_a)
            
      expect(valid_run_diff_name.valid?).to be true
      expect(valid_run_diff_provider.valid?).to be true
      expect(valid_run_diff_date.valid?).to be true
      expect(invalid_run_same_date.valid?).to be false
      expect(valid_run_zipper.valid?).to be true
      expect(invalid_run_collision.valid?).to be false
    end
    
    it 'validates that at least one day of the week is checked' do
      valid_one_day   = build(:repeating_run, :no_repeating_days,
                              repeats_mondays: true)
      valid_many_days = build(:repeating_run, :no_repeating_days,
                              repeats_tuesdays: true, repeats_wednesdays: true, repeats_thursdays: true)
      invalid_no_days = build(:repeating_run, :no_repeating_days)
      
      expect(valid_one_day.valid?).to be true
      expect(valid_many_days.valid?).to be true
      expect(invalid_no_days.valid?).to be false
    end
    
    it 'validates driver availability against daily runs' do
      
      invalid_run_same_driver = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning, driver: run_a.driver)
      valid_run_diff_day = build(:repeating_run, :weekly, :next_week, :scheduled_morning, driver: run_a.driver)
      valid_run_diff_time = build(:repeating_run, :weekly, :tomorrow, :scheduled_afternoon, driver: run_a.driver)
      valid_run_diff_driver = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning)
                  
      expect(invalid_run_same_driver.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_driver.valid?).to be true
      
    end
    
    it 'validates driver availability against other repeating runs' do
      
      invalid_run_same_driver = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning, driver: repeating_run_c.driver)
      valid_run_diff_day = build(:repeating_run, :weekly, :next_week, :scheduled_morning, driver: repeating_run_c.driver)
      valid_run_diff_time = build(:repeating_run, :weekly, :tomorrow, :scheduled_afternoon, driver: repeating_run_c.driver)
      valid_run_diff_driver = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning)
      
      expect(invalid_run_same_driver.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_driver.valid?).to be true
      
    end
    
    it 'validates vehicle availability against daily runs' do
      
      invalid_run_same_vehicle = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning, vehicle: run_a.vehicle)
      valid_run_diff_day = build(:repeating_run, :weekly, :next_week, :scheduled_morning, vehicle: run_a.vehicle)
      valid_run_diff_time = build(:repeating_run, :weekly, :tomorrow, :scheduled_afternoon, vehicle: run_a.vehicle)
      valid_run_diff_vehicle = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning)
                  
      expect(invalid_run_same_vehicle.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_vehicle.valid?).to be true
      
    end
    
    it 'validates driver availability against other repeating runs' do
      
      invalid_run_same_vehicle = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning, vehicle: repeating_run_c.vehicle)
      valid_run_diff_day = build(:repeating_run, :weekly, :next_week, :scheduled_morning, vehicle: repeating_run_c.vehicle)
      valid_run_diff_time = build(:repeating_run, :weekly, :tomorrow, :scheduled_afternoon, vehicle: repeating_run_c.vehicle)
      valid_run_diff_vehicle = build(:repeating_run, :weekly, :tomorrow, :scheduled_morning)
      
      expect(invalid_run_same_vehicle.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_vehicle.valid?).to be true
      
    end
    
  end
  
end
