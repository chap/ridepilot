class FundingAuthorizationNumber < ActiveRecord::Base
  belongs_to :funding_source
  belongs_to :customer, inverse_of: :funding_authorization_numbers

  validates :number, presence: true, length: { maximum: 20}
  
  def self.parse(fundingn_number_hash, customer)
    FundingAuthorizationNumber.new({
      number: fundingn_number_hash[:number],
      contact_info: fundingn_number_hash[:contact_info],
      funding_source_id: fundingn_number_hash[:funding_source_id],
      customer: customer
    })
  end
end
