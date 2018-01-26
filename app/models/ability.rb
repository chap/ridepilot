class Ability
  include CanCan::Ability

  def initialize(user)
    can_manage_all = false

    can :read, Mobility
    can :read, TripPurpose
    can :read, TripResult
    can :read, ServiceLevel
    can :read, Ethnicity
    can :read, FundingSource
    can :read, Region
    can :read, DriverRequirementTemplate
    can :read, VehicleRequirementTemplate
    can :read, VehicleMaintenanceScheduleType
    can :read, VehicleMaintenanceSchedule

    for role in user.roles
      if role.system_admin?
        can_manage_all = true
        can :manage, :all
        break
      end
    end
    
    unless can_manage_all
      for role in user.roles
        can :read, Provider, :id => role.provider.id
        if role.admin?
          can :manage, role.provider
          can :manage, VehicleType, :provider_id => role.provider_id
        end
        
        cannot :create, Provider
        cannot :index, Provider
      end
    end

    provider = user.current_provider
    role = Role.where("provider_id = ? and user_id = ?", provider.id, user.id).first
    if not role
      return
    end
    if provider.active? && role.editor? 
      action = :manage
    else
      action = [:read, :search]
    end

    can action,  Address, :provider_id => provider.id
    can action,  Customer, :provider_id => provider.id
    cannot :update_authorized_providers, Customer unless can_manage_all# only system admin can
    can action,  DevicePool, :provider_id => provider.id if provider.dispatch?
    can action,  DevicePoolDriver, :provider_id => provider.id
    can :manage,  DevicePoolDriver, :driver_id => user.driver.id if provider.active? && user.driver.present?
    can action,  Document, :documentable => {:provider_id => provider.id}
    can action,  Driver, :provider_id => provider.id
    can action,  Monthly, :provider_id => provider.id
    if provider.scheduling?
      # User able to manage trips
      can :manage,  RepeatingTrip, :provider_id => provider.id
      can :manage,  Trip, :provider_id => provider.id 
      can action,  RepeatingRun, :provider_id => provider.id
      can action,  Run, :provider_id => provider.id 
    end
    can action,  Vehicle, :provider_id => provider.id
    
    if provider.active? && role.admin?
      can :manage, DriverCompliance, :driver => {:provider_id => provider.id}
      can :manage, DriverHistory, :driver => {:provider_id => provider.id}
      can :manage, LookupTable
      can :manage, ProviderLookupTable
      can :manage, User, :roles => {:provider_id => provider.id}
      can :manage, VehicleMaintenanceEvent, :vehicle => {:provider_id => provider.id}
      can :manage, VehicleMaintenanceCompliance, :vehicle => {:provider_id => provider.id}
      can :manage, VehicleWarranty, :vehicle => {:provider_id => provider.id}
      can :load,   Address
      can :manage, DriverRequirementTemplate, :provider_id => provider.id
      can :manage, VehicleRequirementTemplate, :provider_id => provider.id
      can :manage, VehicleMaintenanceScheduleType, :provider_id => provider.id
      can :manage, VehicleMaintenanceSchedule, :vehicle_maintenance_schedule_type => { :provider_id => provider.id}
      can :manage, Role do |r|
        r.provider_id == provider.id && !r.system_admin?
      end
      can :manage, ProviderCommonAddress
      can :manage, AddressGroup
    else
      can :read, User, :roles => {:provider_id => provider.id}
      can :manage, user # User can manage themselves
      cannot :delete, Vehicle
      cannot :delete, Driver
    end

    if provider.active? && role.editor?
      can :manage, :cab_trip
      can :manage, RecurringDriverCompliance, :provider_id => provider.id
      can :manage, RecurringVehicleMaintenanceCompliance, :provider_id => provider.id
      # can :edit, Provider, :id => provider.id
    end

    can :access, Reporting::Report
  end
end
