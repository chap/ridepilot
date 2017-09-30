class VehicleMaintenanceCompliancesController < ApplicationController
  load_and_authorize_resource :vehicle
  before_action :load_vehicle_maintenance_compliance
  
  include DocumentAssociableController
  
  respond_to :html, :js

  def index
    @vehicle_maintenance_compliances = @vehicle.vehicle_maintenance_compliances.order(due_mileage: :asc)
    @readonly = params[:readonly] == 'true'

    if params[:show_past] != 'true'
      @vehicle_maintenance_compliances = @vehicle_maintenance_compliances.incomplete.limit(3)
    end
  end

  def show
    prep_edit
    @readonly = true
  end

  # GET /vehicle_maintenance_compliances/new
  def new
    prep_edit
    unless params[:schedule_id].blank?
      schedule = VehicleMaintenanceSchedule.find_by_id(params[:schedule_id])
      if schedule
        @vehicle_maintenance_compliance.vehicle_maintenance_schedule = schedule
        @vehicle_maintenance_compliance.event = schedule.name
        @base_mileage = @vehicle.vehicle_maintenance_compliances.where(vehicle_maintenance_schedule: schedule).complete.maximum(:compliance_mileage)
      end
    end
  end

  # GET /vehicle_maintenance_compliances/1/edit
  def edit
    prep_edit
  end

  # POST /vehicle_maintenance_compliances
  def create
    params = build_new_documents(vehicle_maintenance_compliance_params)
    @vehicle_maintenance_compliance.assign_attributes(params)
    
    if @vehicle_maintenance_compliance.save
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle maintenance compliance was successfully created.' }
        format.js
      end
    else
      show_documents_reminder
      prep_edit
      render :new
    end
  end

  # PATCH/PUT /vehicle_maintenance_compliances/1
  def update
    params = build_new_documents(vehicle_maintenance_compliance_params)

    was_incomplete = !@vehicle_maintenance_compliance.complete?
    if @vehicle_maintenance_compliance.update(params)
      @is_newly_completed = was_incomplete && @vehicle_maintenance_compliance.complete?
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle maintenance compliance was successfully updated.' }
        format.js
      end
    else
      show_documents_reminder
      prep_edit
      render :edit
    end
  end

  # DELETE /vehicle_maintenance_compliances/1
  def destroy
    @vehicle_maintenance_compliance.destroy
    respond_to do |format|
      format.html { redirect_to @vehicle, notice: 'Vehicle maintenance compliance was successfully destroyed.' }
      format.js
    end
  end

  private

  def load_vehicle_maintenance_compliance
    @vehicle_maintenance_compliance = VehicleMaintenanceCompliance.find_by_id(params[:id]) || 
                                      @vehicle.vehicle_maintenance_compliances.build
  end

  def prep_edit
    # @vehicle_maintenance_compliance.document_associations.build
    @vehicle_maintenance_schedule_type = if !params[:vehicle_maintenance_schedule_type_id].blank? 
      VehicleMaintenanceScheduleType.find_by_id(params[:vehicle_maintenance_schedule_type_id])
    elsif !params[:schedule_id].blank?
      schedule = VehicleMaintenanceSchedule.find_by_id params[:schedule_id]
      schedule.vehicle_maintenance_schedule_type if schedule
    else
      @vehicle.vehicle_maintenance_schedule_type || @vehicle_maintenance_compliance.vehicle_maintenance_schedule.try(:vehicle_maintenance_schedule_type)
    end
    @vehicle_maintenance_schedules = @vehicle_maintenance_schedule_type.try(:vehicle_maintenance_schedules) || VehicleMaintenanceSchedule.none
  end

  def vehicle_maintenance_compliance_params
    params.require(:vehicle_maintenance_compliance).permit(
      :event, 
      :notes, 
      :due_type, 
      :due_date, 
      :due_mileage, 
      :compliance_date, 
      :compliance_mileage, 
      :vehicle_maintenance_schedule_id, 
      documents_attributes: documents_attributes
    )
  end
end
