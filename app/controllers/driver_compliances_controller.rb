class DriverCompliancesController < ApplicationController
  load_and_authorize_resource :driver
  before_action :load_driver_compliance
  
  include DocumentAssociableController
  
  respond_to :html, :js

  def index
    @driver_compliances = @driver.driver_compliances.default_order
    @readonly = params[:readonly] == 'true'

    if params[:show_past] != 'true'
      @driver_compliances = @driver_compliances.incomplete
    end

    if params[:legal] != 'true'
      @driver_compliances = @driver_compliances.non_legal
    else
      @driver_compliances = @driver_compliances.legal
    end
  end

  def show
    @readonly = true
  end

  # GET /driver_compliances/new
  def new
    unless params["driver_requirement_template_id"].blank?
      @driver_compliance.driver_requirement_template_id = params["driver_requirement_template_id"]
      @driver_compliance.event = @driver_compliance.driver_requirement_template.try(:name)
    end
  end

  # GET /driver_compliances/1/edit
  def edit
  end

  # POST /driver_compliances
  def create
    params = build_new_documents(driver_compliance_params)
    @driver_compliance.assign_attributes(params)
    
    if @driver_compliance.save
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver compliance was successfully created.' }
        format.js
      end
    else
      show_documents_reminder
      render :new
    end
  end

  # PATCH/PUT /driver_compliances/1
  def update
    params = build_new_documents(driver_compliance_params)
    was_incomplete = !@driver_compliance.complete?
    if @driver_compliance.update(params)
      @is_newly_completed = was_incomplete && @driver_compliance.complete?
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver compliance was successfully updated.' }
        format.js
      end
    else
      show_documents_reminder
      render :edit
    end
  end

  # DELETE /driver_compliances/1
  def destroy
    @driver_compliance.destroy
    respond_to do |format|
      format.html { redirect_to @driver, notice: 'Driver compliance was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def load_driver_compliance
    @driver_compliance = DriverCompliance.find_by_id(params[:id]) || @driver.driver_compliances.build
  end

  def driver_compliance_params
    params.require(:driver_compliance).permit(
      :event, 
      :notes, 
      :due_date, 
      :compliance_date, 
      :legal,
      :driver_requirement_template_id,
      documents_attributes: documents_attributes
    )
  end
end
