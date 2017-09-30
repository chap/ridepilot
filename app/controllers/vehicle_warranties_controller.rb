class VehicleWarrantiesController < ApplicationController
  load_and_authorize_resource :vehicle
  before_action :load_vehicle_warranty
  
  include DocumentAssociableController
  
  respond_to :html, :js

  # GET /vehicle_warranties/new
  def new
  end

  def show
    @readonly = true
  end

  # GET /vehicle_warranties/1/edit
  def edit
  end

  # POST /vehicle_warranties
  def create
    params = build_new_documents(vehicle_warranty_params)
    @vehicle_warranty.assign_attributes(params)
    
    if @vehicle_warranty.save
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle warranty was successfully created.' }
        format.js
      end
    else
      show_documents_reminder
      render :new
    end
  end

  # PATCH/PUT /vehicle_warranties/1
  def update
    params = build_new_documents(vehicle_warranty_params)
    
    if @vehicle_warranty.update(params)
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle warranty was successfully updated.' }
        format.js
      end
    else
      show_documents_reminder
      render :edit
    end
  end

  # DELETE /vehicle_warranties/1
  def destroy
    @vehicle_warranty.destroy
    respond_to do |format|
      format.html { redirect_to @vehicle, notice: 'Vehicle warranty was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def load_vehicle_warranty
    @vehicle_warranty = VehicleWarranty.find_by_id(params[:id]) || 
                        @vehicle.vehicle_warranties.build
  end

  def vehicle_warranty_params
    params.require(:vehicle_warranty).permit(
      :description, 
      :notes, 
      :expiration_date, 
      documents_attributes: documents_attributes
    )
  end
end
