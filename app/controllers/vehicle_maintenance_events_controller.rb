class VehicleMaintenanceEventsController < ApplicationController
  load_and_authorize_resource :vehicle
  before_action :load_vehicle_maintenance_event
  
  include DocumentAssociableController
  
  respond_to :html, :js

  # GET /vehicle_maintenance_events/new
  def new
  end

  # GET /vehicle_maintenance_events/1/edit
  def edit
  end

  def show
    @readonly = true
  end

  # POST /vehicle_maintenance_events
  def create
    params = build_new_documents(vehicle_maintenance_event_params)
    @vehicle_maintenance_event.assign_attributes(params)
    
    if @vehicle_maintenance_event.save
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle maintenance event was successfully created.' }
        format.js
      end
    else
      show_documents_reminder
      render :new
    end 
  end

  # PATCH/PUT /vehicle_maintenance_events/1
  def update
    params = build_new_documents(vehicle_maintenance_event_params)
    
    if @vehicle_maintenance_event.update(params)
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle maintenance event was successfully updated.' }
        format.js
      end
    else
      show_documents_reminder
      render :edit
    end
  end

  # DELETE /vehicle_maintenance_events/1
  def destroy
    @vehicle_maintenance_event.destroy
    respond_to do |format|
      format.html { redirect_to @vehicle, notice: 'Vehicle maintenance event was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def load_vehicle_maintenance_event
    @vehicle_maintenance_event = VehicleMaintenanceEvent.find_by_id(params[:id]) || 
                                 @vehicle.vehicle_maintenance_events.build
  end

  def vehicle_maintenance_event_params
    params.require(:vehicle_maintenance_event).permit(
      :vehicle_id, 
      :reimbursable, 
      :service_date, 
      :invoice_date, 
      :services_performed, 
      :odometer, 
      :vendor_name, 
      :invoice_number, 
      :invoice_amount, 
      documents_attributes: documents_attributes
    )
  end  
end
