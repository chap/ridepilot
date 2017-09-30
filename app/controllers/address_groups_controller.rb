class AddressGroupsController < ApplicationController
  before_action :set_address_group, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /address_groups
  def index
    @address_groups = AddressGroup.all
  end

  # GET /address_groups/1
  def show
  end

  # GET /address_groups/new
  def new
    @address_group = AddressGroup.new
  end

  # GET /address_groups/1/edit
  def edit
  end

  # POST /address_groups
  def create
    @address_group = AddressGroup.new(address_group_params)

    if @address_group.save
      respond_to do |format|
        format.html {
          redirect_to @address_group, notice: 'Address group was successfully created.'
        }
        format.json {
          render json: @address_group
        }
      end
    else
      respond_to do |format|
        format.html {
          render :new
        }
        format.json {
          render json: @address_group.errors
        }
      end
    end
  end

  # PATCH/PUT /address_groups/1
  def update
    if @address_group.update(address_group_params)
      redirect_to @address_group, notice: 'Address group was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /address_groups/1
  def destroy
    @address_group.destroy
    redirect_to address_groups_url, notice: 'Address group was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_address_group
      @address_group = AddressGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def address_group_params
      params.require(:address_group).permit(:name)
    end
end
