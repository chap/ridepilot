class TripsRunsController < ApplicationController
  before_action :authorization

  def index
    Date.beginning_of_week= :sunday
    filters_hash = runs_trips_params || {}
    update_sessions(filters_hash.except(:start, :end))

    # by default, select all trip results
    unless session[:trip_result_id].present?
      session[:trip_result_id] = [TripResult::UNSCHEDULED_ID, TripResult::SHOW_ALL_ID] + TripResult.pluck(:id).uniq
    end
    
    @runs = Run.for_provider(current_provider_id).order(:name, :date, :scheduled_start_time)
    @runs = @runs.where(id: filters_hash[:run_id]) unless filters_hash[:run_id].blank?
    filter_runs

    @trips = Trip.has_scheduled_time.for_provider(current_provider_id).includes(:customer, :pickup_address, :run)
    .references(:customer, :pickup_address, :run).order(:pickup_time)
    # Exclude trips with following result codes from trips-runs page
    exclude_trip_result_ids = TripResult.non_dispatchable_result_ids
    @trips = @trips.where("trip_result_id is NULL or trip_result_id not in (?)", exclude_trip_result_ids)
    filter_trips
    
    @run_trip_day    = Utility.new.parse_date(session[:run_trip_day])

    base_runs = @runs
    base_runs = add_cab_run(base_runs) if current_provider.try(:cab_enabled?)

    @runs_for_dropdown = add_unscheduled_run(base_runs).collect {|r| [r.label, r.id]}

    respond_to do |format|
      format.html
    end
  end

  def schedule
    respond_to do |format|
      format.js { render json: TripScheduler.new(params[:trip_id], params[:run_id]).execute }
    end
  end

  # Ajax to update Run filter given a new date
  def runs_by_date
    @runs = Run.for_provider(current_provider_id).for_date(Utility.new.parse_date(params[:run_trip_day])).order(:name)
  end
  
  private

  def authorization
    authorize! :read, Run, :provider_id => current_provider_id
    authorize! :read, Trip, :provider_id => current_provider_id
  end

  def filter_trips
    trip_filter = TripFilter.new(@trips, trip_sessions)
    @trips = trip_filter.filter!

  end

  def filter_runs
    run_filter = RunFilter.new(@runs, run_sessions)
    @runs = run_filter.filter!
  end

  def runs_trips_params
    raw_params = params[:run_trip_filters] || {}
    
    if params[:run_trip_filters]
      raw_params[:run_trip_day] = Date.today.in_time_zone.to_i if raw_params[:run_trip_day].blank?
    else
      if session[:run_trip_day]
        raw_params[:run_trip_day] = Utility.new.parse_date(session[:run_trip_day]).try(:to_i) 
      else
        raw_params[:run_trip_day] = Date.today.in_time_zone.to_i
      end
    end

    raw_params
  end

  def update_sessions(params = {})
    params.each do |key, val|
      session[key] = val if !val.nil?
    end
  end

  def run_sessions
    {
      start: session[:run_trip_day],
      end: session[:run_trip_day], 
      run_id: session[:run_id], 
      run_result_id: session[:run_result_id]
    }
  end

  def trip_sessions
    {
      start: session[:run_trip_day],
      end: session[:run_trip_day],  
      run_id: session[:run_id], 
      trip_result_id: session[:trip_result_id], 
      status_id: session[:status_id]
    }
  end

  def add_cab_run(runs)
    runs + [Run.fake_cab_run]
  end

  def add_unscheduled_run(runs)
    runs + [Run.fake_unscheduled_run]
  end
end
