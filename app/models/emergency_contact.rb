class EmergencyContact < ActiveRecord::Base
  acts_as_paranoid # soft delete
  belongs_to :driver, -> { with_deleted }
  belongs_to :geocoded_address, -> { with_deleted }
  accepts_nested_attributes_for :geocoded_address, update_only: true

  validates :name, presence: true
  validate :valid_phone_number

  private 
  
  def valid_phone_number
    util = Utility.new
    if phone_number.present?
      errors.add(:phone_number, 'is invalid') unless util.phone_number_valid?(phone_number) 
    end
  end
  
end
