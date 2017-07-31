class AddressGroup < ActiveRecord::Base

  validates :name, uniqueness: { case_insensitive: true }, presence: true

  normalize_attribute :name, :with => [ :strip ]

  UNKNOWN_TYPE = 'Needs Update'

  def self.default_address_group
    find_by_name UNKNOWN_TYPE
  end
end
