require 'active_support/concern'

module RequirementTemplate
  extend ActiveSupport::Concern

  included do
    belongs_to :provider

    acts_as_paranoid # soft delete

    validates :name, presence: true

    scope :system_wide,   -> { where(provider: nil) }
    scope :provider_only,  -> (provider_id) { where(provider_id: provider_id) }
    scope :provider_accessible, -> (provider_id) { where("provider_id is NULL or provider_id = ?", provider_id) }
    scope :legal,         -> { where(legal: true) }
    scope :non_legal,     -> { where("legal is NULL or legal = ?", false) }
  end

end
