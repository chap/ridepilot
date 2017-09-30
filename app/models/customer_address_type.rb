class CustomerAddressType < ActiveRecord::Base
  acts_as_paranoid # soft delete
  
  validates_presence_of :code, :name

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids)
  end
end
