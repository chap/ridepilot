require 'active_support/concern'

module Lookupable
  extend ActiveSupport::Concern

  included do
    # Each lookup table can have three columns associated: value, code, description
    # e.g., TripResult has all three, but mostly only has one column, which is used as 'value' to identify each record
    # Eligibility is a special case, because its value column is named as code, so value_column_name should be 'code'
    validates_presence_of :name, :caption, :value_column_name
    validates_uniqueness_of :name
    normalize_attribute :name, :with => [ :strip ]

    def model
      (model_name || name.classify).constantize
    end

    def find_by_value(value)
      model.find_by("#{value_column_name}": value)
    end

    def get_value(model_id)
      model.find_by_id(model_id)
    end
  end
  
 
end
