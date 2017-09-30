class FundingSource < ActiveRecord::Base
  acts_as_paranoid # soft delete
  has_paper_trail

  validates_presence_of :name
  validates_length_of :name, minimum: 2

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids).where("provider_id is NULL or provider_id = ?", provider.try(:id))
  end
end
