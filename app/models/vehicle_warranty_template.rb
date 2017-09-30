class VehicleWarrantyTemplate < ActiveRecord::Base
  belongs_to :provider

  validates_presence_of :name

  scope :by_provider, ->(provider_id) { where(provider_id: provider_id) }

end
