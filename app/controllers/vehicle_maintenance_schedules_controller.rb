class VehicleMaintenanceSchedulesController < ApplicationController
  load_and_authorize_resource :vehicle_maintenance_schedule_type
  load_and_authorize_resource :vehicle_maintenance_schedule, through: :vehicle_maintenance_schedule_type, except: [:create]
  before_action :load_document, except: [:index]

  respond_to :html, :js

  def index
    @vehicle_maintenance_schedules = @vehicle_maintenance_schedule_type.vehicle_maintenance_schedules.order(:mileage)
  end

  def new
  end

  def create
    @vehicle_maintenance_schedule.assign_attributes(schedule_params)
    @vehicle_maintenance_schedule.vehicle_maintenance_schedule_type = @vehicle_maintenance_schedule_type
    if @vehicle_maintenance_schedule.save
      respond_to do |format|
        format.js
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    
    if @vehicle_maintenance_schedule.update(schedule_params)
      respond_to do |format|
        format.js
      end
    else
      render :edit
    end
  end

  def destroy
    @vehicle_maintenance_schedule.destroy
    respond_to do |format|
      format.js
    end
  end

  private
  
  def load_document
    @vehicle_maintenance_schedule ||= VehicleMaintenanceSchedule.new
    @document = @vehicle_maintenance_schedule.document || 
                @vehicle_maintenance_schedule.build_document(description: "Inspection Report")
  end

  def schedule_params
    safe_params = vehicle_maintenance_schedule_params
    
    document_attributes = safe_params[:document_attributes]
    unless document_attributes_valid?(document_attributes)
      safe_params.delete(:document_attributes) 
      @vehicle_maintenance_schedule.document = nil
    end
    
    safe_params
  end
  
  def vehicle_maintenance_schedule_params
    params.require(:vehicle_maintenance_schedule).permit(
      :name, 
      :mileage,
      :vehicle_maintenance_schedule_type,
      document_attributes: [:id, :document, :description, :_destroy]
    )
  end
  
  def document_attributes_valid?(document_attributes)
    document_attributes[:_destroy].to_i > 0 ||
    (document_attributes[:description].present? && document_attributes[:document].present?)
  end
  
end
