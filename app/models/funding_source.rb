class FundingSource < ActiveRecord::Base
  acts_as_paranoid # soft delete
  has_paper_trail

  validates_presence_of :name
  validates_length_of :name, minimum: 2
  validate :name_uniqueness

  scope :across_system,       -> { where(provider_id: nil) }
  scope :provider_specific,   ->(provider_id) { where(provider_id: provider_id) }
  scope :ntd_reportable,      -> { where(ntd_reportable: true) }

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids).where("provider_id is NULL or provider_id = ?", provider.try(:id))
  end

  private

  def name_uniqueness
    if FundingSource.where("deleted_at is NULL and lower(name) = ? and (provider_id is NULL or provider_id = ?)", name.try(:downcase), provider_id).any?
      errors.add(:base, "Name has already been taken")
    end
  end
end
