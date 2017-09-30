class RepeatingTripsController < ApplicationController
  before_action :set_trip, except: [:index, :new, :create, :clone_from_daily_run]
  authorize_resource :except=>[:show]

  def index
    @trips = RepeatingTrip.active.for_provider(current_provider_id).order(created_at: :desc)
  end

  def new
    @trip = RepeatingTrip.new(:provider_id => current_provider_id)

    prep_view
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def edit
    prep_view
    
    respond_to do |format|
      format.html 
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end
  
  def show
    @trip = RepeatingTrip.find(params[:id])
    prep_view

    authorize! :show, @trip unless @trip.customer && @trip.customer.authorized_for_provider(current_provider.id)
    
    respond_to do |format|
      format.html 
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end

  def create
    params[:repeating_trip][:provider_id] = current_provider_id   
    @trip = RepeatingTrip.new(trip_params)
    process_google_address
    authorize! :manage, @trip

    respond_to do |format|
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        format.html {
          TrackerActionLog.create_subscription_trip(@trip, current_user)
          redirect_to @trip, :notice => 'Subscription trip template was successfully created.'
        }
      else
        prep_view
        format.html { render :action => "new" }
      end
    end

  end

  def update
    if params[:repeating_trip][:customer_id] && customer = Customer.find_by_id(params[:repeating_trip][:customer_id])
      authorize! :read, customer
    else
      params[:repeating_trip][:customer_id] = @trip.customer_id
    end    
    process_google_address
    authorize! :manage, @trip

    prev_schedule = @trip.schedule
    @trip.assign_attributes(trip_params)
    changes = @trip.changes
    respond_to do |format|
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        TrackerActionLog.update_subscription_trip(@trip, current_user, changes, prev_schedule)
        format.html { redirect_to(@trip, :notice => 'Trip was successfully updated.')  }
      else
        prep_view
        format.html { render :action => "edit"  }
      end
    end
  end

  def destroy
    @trip.destroy

    respond_to do |format|
      format.html { redirect_to(repeating_trips_url) }
      format.xml  { head :ok }
      format.js   { render :json => {:status => "success"}, :content_type => "text/json" }
    end
  end

  # use another repeating trip as template
  def clone
    @trip = @trip.clone_for_future!
    prep_view
    
    respond_to do |format|
      format.html { render action: :new }
    end
  end

  # use daily trip as template
  def clone_from_daily_trip
    daily_trip = Trip.find_by_id(params[:trip_id])
    if daily_trip.present?
      @trip = daily_trip.clone_for_repeating_trip!
    else
      @trip = RepeatingTrip.new(:provider_id => current_provider_id)
    end

    prep_view
    
    respond_to do |format|
      format.html { render action: :new }
    end
  end

  private

  def set_trip
    @trip = RepeatingTrip.find_by_id(params[:id])
  end
  
  def trip_params
    params.require(:repeating_trip).permit(
      :appointment_time,
      :attendant_count,
      :customer_id,
      :dropoff_address_id,
      :funding_source_id,
      :group_size,
      :guest_count,
      :medicaid_eligible,
      :mobility_id,
      :notes,
      :pickup_address_id,
      :pickup_time,
      :provider_id, # We normally wouldn't accept this and would set it manually on the instance, but in this controller we're setting it in the params dynamically
      :repeats_sundays,
      :repeats_mondays,
      :repeats_tuesdays,
      :repeats_wednesdays,
      :repeats_thursdays,
      :repeats_fridays,
      :repeats_saturdays,
      :repetition_interval,
      :service_level_id,
      :trip_purpose_id,
      :customer_informed,
      :mobility_device_accommodations,
      :comments,
      :start_date,
      :end_date,
      customer_attributes: [:id]
    )
  end

  def prep_view
    @customer           = @trip.customer
    @mobilities         = Mobility.by_provider(current_provider).order(:name)
    @funding_sources    = FundingSource.by_provider(current_provider)
    @trip_purposes      = TripPurpose.by_provider(current_provider).order(:name)
    @drivers            = Driver.active.for_provider @trip.provider_id
    @vehicles           = Vehicle.active.for_provider(@trip.provider_id)
    @vehicles           = add_cab(@vehicles) if current_provider.try(:cab_enabled?)
    
    @repeating_vehicles = @vehicles 
    @service_levels     = ServiceLevel.by_provider(current_provider).order(:name).pluck(:name, :id)
  end

  def add_cab(vehicles)
    cab_vehicle = Vehicle.new :name => "Cab"
    cab_vehicle.id = -1
    [cab_vehicle] + vehicles 
  end

  def process_google_address
    if params[:repeating_trip][:pickup_address_id].blank? && !params[:trip_pickup_google_address].blank?
      addr_params = JSON(params[:trip_pickup_google_address])
      new_temp_addr = TempAddress.new(addr_params.select{|x| TempAddress.allowable_params.include?(x) })
      new_temp_addr.the_geom = RGeo::Geographic.spherical_factory(srid: 4326).point(addr_params['lon'].to_f, addr_params['lat'].to_f)
      @trip.pickup_address = new_temp_addr
    end

    if params[:repeating_trip][:dropoff_address_id].blank? && !params[:trip_dropoff_google_address].blank?
      addr_params = JSON(params[:trip_dropoff_google_address])
      new_temp_addr = TempAddress.new(addr_params.select{|x| TempAddress.allowable_params.include?(x)})
      new_temp_addr.the_geom = RGeo::Geographic.spherical_factory(srid: 4326).point(addr_params['lon'].to_f, addr_params['lat'].to_f)
      @trip.dropoff_address = new_temp_addr
    end
        
  end
end