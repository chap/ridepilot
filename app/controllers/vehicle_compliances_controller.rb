class VehicleCompliancesController < ApplicationController
  load_and_authorize_resource :vehicle
  before_action :load_vehicle_compliance
  
  include DocumentAssociableController
  
  respond_to :html, :js

  def index
    @vehicle_compliances = @vehicle.vehicle_compliances.default_order
    @readonly = params[:readonly] == 'true'

    if params[:show_past] != 'true'
      @vehicle_compliances = @vehicle_compliances.incomplete
    end

    if params[:legal] != 'true'
      @vehicle_compliances = @vehicle_compliances.non_legal
    else
      @vehicle_compliances = @vehicle_compliances.legal
    end
  end

  def show
    @readonly = true
  end

  # GET /vehicle_compliances/new
  def new
    unless params["vehicle_requirement_template_id"].blank?
      @vehicle_compliance.vehicle_requirement_template_id = params["vehicle_requirement_template_id"]
      @vehicle_compliance.event = @vehicle_compliance.vehicle_requirement_template.try(:name)
    end
  end

  # GET /vehicle_compliances/1/edit
  def edit
  end

  # POST /vehicle_compliances
  def create
    params = build_new_documents(vehicle_compliance_params)
    @vehicle_compliance.assign_attributes(params)
    
    if @vehicle_compliance.save
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle compliance was successfully created.' }
        format.js
      end
    else
      show_documents_reminder
      render :new
    end
  end

  # PATCH/PUT /vehicle_compliances/1
  def update
    params = build_new_documents(vehicle_compliance_params)
    was_incomplete = !@vehicle_compliance.complete?
    if @vehicle_compliance.update(params)
      @is_newly_completed = was_incomplete && @vehicle_compliance.complete?
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle compliance was successfully updated.' }
        format.js
      end
    else
      show_documents_reminder
      render :edit
    end
  end

  # DELETE /vehicle_compliances/1
  def destroy
    @vehicle_compliance.destroy
    respond_to do |format|
      format.html { redirect_to @vehicle, notice: 'Vehicle compliance was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def load_vehicle_compliance
    @vehicle_compliance = VehicleCompliance.find_by_id(params[:id]) || @vehicle.vehicle_compliances.build
  end

  def vehicle_compliance_params
    params.require(:vehicle_compliance).permit(
      :event, 
      :notes, 
      :due_date, 
      :compliance_date, 
      :legal,
      :vehicle_requirement_template_id,
      documents_attributes: documents_attributes
    )
  end
end
