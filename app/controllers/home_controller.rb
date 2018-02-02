class HomeController < ApplicationController

  def index
    authorize! :read, current_user
  end

  def schedule_recurring
    if !Rails.env.production? || ENV['HAS_RECURRING_TRIP_RUN_SCHDULING_BUTTON'] == 'true'
      RepeatingRun.active.generate!
      RepeatingTrip.active.generate!
      Run.today_and_future.batch_update_recurring_trip_assignment!
    end

    redirect_to :back 
  end

  def ntd_funding_sources
    get_base_funding_sources
  end

  def update_ntd_funding_sources
    get_base_funding_sources

    unless params["ntd_funding_source_ids"].blank?
      ntd_source_ids = params["ntd_funding_source_ids"].split(',') 
      @funding_sources.where(id: ntd_source_ids).update_all(ntd_reportable: true)
      @funding_sources.where.not(id: ntd_source_ids).update_all(ntd_reportable: false)
    end
  end

  private

  def get_base_funding_sources
    if params[:provider] == 'true'
      @funding_sources = FundingSource.provider_specific(current_provider_id).order(:name)
    else
      authorize! :manage, :all
      @funding_sources = FundingSource.across_system.order(:name)
    end
  end
end
