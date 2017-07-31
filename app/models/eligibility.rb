class Eligibility < ActiveRecord::Base
  has_paper_trail
  
  validates :code, presence: true, uniqueness: true
  validates :description, presence: true

  normalize_attribute :code, :with => [ :strip ]

  has_many :customers, through: :customer_eligibilities
  has_many :customer_eligibilities

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids)
  end
end

