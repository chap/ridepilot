class DriverRequirementTemplatesController < ApplicationController
  load_and_authorize_resource except: [:create]
  before_action :guard_system_template_permission, except: [:create]

  def index
    if params[:provider_id].blank?
      @driver_requirement_templates = DriverRequirementTemplate.system_wide
    else
      @driver_requirement_templates = DriverRequirementTemplate.provider_only(params[:provider_id])
    end

    @driver_requirement_templates.order(:name, :legal)
  end

  def show
    @readonly = true
  end

  def new
  end

  def create
    @driver_requirement_template = DriverRequirementTemplate.new template_params

    if @driver_requirement_template.provider_id.blank?
      authorize! :manage, :system_driver_requirement_template
    else
      authorize! :manage, @driver_requirement_template
    end

    if @driver_requirement_template.save
      redirect_to driver_requirement_template_path(@driver_requirement_template, provider_id: @driver_requirement_template.provider_id)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @driver_requirement_template.update_attributes template_params
      redirect_to driver_requirement_template_path(@driver_requirement_template,provider_id: @driver_requirement_template.provider_id)
    else
      render 'edit'
    end
  end

  def destroy
    !@driver_requirement_template.destroy
    redirect_to driver_requirement_templates_path(provider_id: params[:provider_id])
  end

  private

  def template_params
    params.require(:driver_requirement_template).permit(:name, :provider_id, :legal, :reoccuring)
  end

  def guard_system_template_permission
    if params[:provider_id].blank?
      authorize! :manage, :system_driver_requirement_template
    end
  end
end