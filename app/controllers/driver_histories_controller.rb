class DriverHistoriesController < ApplicationController
  load_and_authorize_resource :driver
  before_action :load_driver_history
  
  include DocumentAssociableController
  
  respond_to :html, :js

  # GET /driver_histories/new
  def new
  end

  # GET /driver_histories/1/edit
  def edit
  end

  def show
    @readonly = true
  end

  # POST /driver_histories
  def create
    puts "DH CREATE"
    puts params.inspect
    params = build_new_documents(driver_history_params)
    @driver_history.assign_attributes(params)
    
    if @driver_history.save
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver history was successfully created.' }
        format.js
      end
    else
      show_documents_reminder
      render :new
    end
  end

  # PATCH/PUT /driver_histories/1
  def update
    params = build_new_documents(driver_history_params)
            
    if @driver_history.update(params)
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver history was successfully updated.' }
        format.js
      end
    else
      show_documents_reminder
      render :edit
    end
  end

  # DELETE /driver_histories/1
  def destroy
    @driver_history.destroy
    respond_to do |format|
      format.html { redirect_to @driver, notice: 'Driver history was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def load_driver_history
    @driver_history = DriverHistory.find_by_id(params[:id]) || 
                      @driver.driver_histories.build
  end

  def driver_history_params
    params.require(:driver_history).permit(
      :event, 
      :notes, 
      :event_date,
      documents_attributes: documents_attributes
    )
  end
end
