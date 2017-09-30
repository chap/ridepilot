class AdaQuestion < ActiveRecord::Base
  belongs_to :provider

  has_many   :customer_ada_questions, dependent: :destroy
  
  validates_presence_of :name

  scope :by_provider, ->(provider_id) { where(provider_id: provider_id) }
end
