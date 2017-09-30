class VehicleMaintenanceScheduleTypesController < ApplicationController
  load_and_authorize_resource except: [:create]

  respond_to :html, :js

  def index
    @vehicle_maintenance_schedule_types = VehicleMaintenanceScheduleType.for_provider(current_provider_id)
  end

  def show
  end

  def new
  end

  def create
    @vehicle_maintenance_schedule_type = VehicleMaintenanceScheduleType.new(schedule_type_params)
    @vehicle_maintenance_schedule_type.provider_id = current_provider_id
    if @vehicle_maintenance_schedule_type.save
      respond_to do |format|
        format.html { redirect_to vehicle_maintenance_schedule_types_path, notice: 'A new schedule type was successfully created.' }
        format.js
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @vehicle_maintenance_schedule_type.update(schedule_type_params)
      respond_to do |format|
        format.html { redirect_to @vehicle_maintenance_schedule_type, notice: 'Schedule type was successfully updated.' }
        format.js
      end
    else
      render :edit
    end
  end

  def destroy
    @vehicle_maintenance_schedule_type.destroy
    respond_to do |format|
      format.html { redirect_to vehicle_maintenance_schedule_types_path, notice: 'Schedule type was successfully destroyed.' }
      format.js
    end
  end

  private

  def schedule_type_params
    params.require(:vehicle_maintenance_schedule_type).permit(:name)
  end
end