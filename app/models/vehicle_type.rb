class VehicleType < ActiveRecord::Base
  has_many :vehicle_capacities, dependent: :destroy, foreign_key: :host_id
  belongs_to :provider

  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :provider_id, message: 'should be unique within a provider' }
  normalize_attribute :name, :with => [ :strip ]

  scope :for_provider, -> (provider_id) { where(provider_id: provider_id)}
  scope :default_order, -> { order(:name) }
end
