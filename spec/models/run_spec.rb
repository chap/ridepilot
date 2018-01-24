require "rails_helper"

RSpec.describe Run, type: :model do
  
  describe 'validations' do
    # Set some context...
    let(:provider_a) { create(:provider) }
    let(:provider_b) { create(:provider) }
    let!(:run_a) { create(:run, :tomorrow, :scheduled_morning, name: "Run A", provider: provider_a) }
    let!(:repeating_run_c) { create(:repeating_run, :weekly, :tomorrow, :scheduled_morning, name: "Run C", provider: provider_a) }
    
    it 'validates name uniqueness among daily runs by date and provider' do
      valid_run_diff_name = build(:run, :tomorrow, name: "Run B", provider: provider_a)
      valid_run_diff_provider = build(:run, :tomorrow, name: "Run A", provider: provider_b)
      valid_run_diff_date = build(:run, :next_week, name: "Run A", provider: provider_a)
      invalid_run = build(:run, :tomorrow, name: "Run A", provider: provider_a)
      
      expect(valid_run_diff_name.valid?).to be true
      expect(valid_run_diff_provider.valid?).to be true
      expect(valid_run_diff_date.valid?).to be true
      expect(invalid_run.valid?).to be false
    end
    
    it 'validates name uniqueness among repeating runs by date and provider' do
      
      valid_run_diff_name = build(:run, :tomorrow, name: "Run D", provider: provider_a)
      valid_run_diff_provider = build(:run, :tomorrow, name: "Run C", provider: provider_b)
      valid_run_diff_date = build(:run, :next_week, name: "Run C", provider: provider_a)
      invalid_run_this_week = build(:run, :tomorrow, name: "Run C", provider: provider_a)
      invalid_run_next_week = build(:run, date: Date.tomorrow + 1.week, name: "Run C", provider: provider_a)
      
      expect(valid_run_diff_name.valid?).to be true
      expect(valid_run_diff_provider.valid?).to be true
      expect(valid_run_diff_date.valid?).to be true
      expect(invalid_run_this_week.valid?).to be false
      expect(invalid_run_next_week.valid?).to be false
    end
    
    it 'validates driver availability against other daily runs' do
      
      invalid_run_same_driver = build(:run, :tomorrow, :scheduled_morning, driver: run_a.driver)
      valid_run_diff_day = build(:run, :next_week, :scheduled_morning, driver: run_a.driver)
      valid_run_diff_time = build(:run, :tomorrow, :scheduled_afternoon, driver: run_a.driver)
      valid_run_diff_driver = build(:run, :tomorrow, :scheduled_morning)
      
      expect(invalid_run_same_driver.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_driver.valid?).to be true
      
    end
    
    it 'validates vehicle availability against other daily runs' do
      
      invalid_run_same_vehicle = build(:run, :tomorrow, :scheduled_morning, vehicle: run_a.vehicle)
      valid_run_diff_day = build(:run, :next_week, :scheduled_morning, vehicle: run_a.vehicle)
      valid_run_diff_time = build(:run, :tomorrow, :scheduled_afternoon, vehicle: run_a.vehicle)
      valid_run_diff_vehicle = build(:run, :tomorrow, :scheduled_morning)
      
      expect(invalid_run_same_vehicle.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_vehicle.valid?).to be true
      
    end
    
    it 'validates vehicle availability against repeating runs' do
      
      invalid_run_same_vehicle = build(:run, :tomorrow, :scheduled_morning, vehicle: repeating_run_c.vehicle)
      valid_run_diff_day = build(:run, :next_week, :scheduled_morning, vehicle: repeating_run_c.vehicle)
      valid_run_diff_time = build(:run, :tomorrow, :scheduled_afternoon, vehicle: repeating_run_c.vehicle)
      valid_run_diff_vehicle = build(:run, :tomorrow, :scheduled_morning)
      
      expect(invalid_run_same_vehicle.valid?).to be false
      expect(valid_run_diff_day.valid?).to be true
      expect(valid_run_diff_time.valid?).to be true
      expect(valid_run_diff_vehicle.valid?).to be true
      
    end
    
    skip 'skips driver availability validation for child runs' do
            
      child_run_same_driver = build(:run, :child_run, :tomorrow, :scheduled_morning, driver: run_a.driver)
      expect(child_run_same_driver.valid?).to be true
      
      # Now make child run a daily run by setting repeating_run to nil
      child_run_same_driver.repeating_run_id = nil
      expect(child_run_same_driver.valid?).to be false
      
    end
    
    skip 'checks availability for child runs as if they were daily runs' do
      
      child_run_same_driver = build(:run, :child_run, :tomorrow, :scheduled_morning, driver: run_a.driver)
      expect(child_run_same_driver.valid?).to be true
      expect(child_run_same_driver.valid_as_daily_run?).to be false
      
    end
  end

  describe 'manifest changes' do
    let(:provider_a) { create(:provider) }
    let!(:run) { create(:run, :today, :scheduled_morning, provider: provider_a, scheduled_start_time: Date.today.beginning_of_day, scheduled_end_time: Date.today.end_of_day) }
    let(:trip) { create(:trip, run: run) }

    describe "#add_trip_manifest!" do 
      before do 
      end

      it "add itineraries" do
        expect{run.add_trip_manifest!(trip.id)}.to change{run.itineraries.count}.from(0).to(2)
      end

      it "updates manifest_order" do 
        run.add_trip_manifest!(trip.id)
        expect(run.manifest_order).to match_array(["trip_#{trip.id}_leg_1", "trip_#{trip.id}_leg_2"])
      end
    end

    describe "#delete_trip_manifest!" do 
      before do 
        run.add_trip_manifest!(trip.id)
      end

      it "remove itineraries" do
        expect{run.delete_trip_manifest!(trip.id)}.to change{run.itineraries.count}.from(2).to(0)
      end

      it "updates manifest_order" do 
        run.delete_trip_manifest!(trip.id)
        expect(run.manifest_order).to eq([])
      end
    end

    describe "#sorted_itineraries" do 
      before do 
        day_base = Date.today.beginning_of_day
        @trip_1 = create(:trip, pickup_time: day_base + 8.hours, appointment_time: day_base + 10.hours, run: run)
        @trip_2 = create(:trip, pickup_time: day_base + 9.hours, appointment_time: day_base + 11.hours, run: run)

        run.add_trip_manifest!(@trip_1.id)
        run.add_trip_manifest!(@trip_2.id)
      end

      it "returns correct itineraries in order" do 
        sorted_itineraries = run.sorted_itineraries
        expect(sorted_itineraries.size).to eq(4)
        expect(sorted_itineraries.collect(&:itin_id)).to match_array(["trip_#{@trip_1.id}_leg_1", "trip_#{@trip_2.id}_leg_1", "trip_#{@trip_1.id}_leg_2", "trip_#{@trip_2.id}_leg_2"])
      end

      it "is in sync with manifest_order" do 
        expect(run.manifest_order).to match_array(["trip_#{@trip_1.id}_leg_1", "trip_#{@trip_2.id}_leg_1", "trip_#{@trip_1.id}_leg_2", "trip_#{@trip_2.id}_leg_2"])
      end
    end
  end
end
