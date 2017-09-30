class ProviderLookupTable < ActiveRecord::Base  
  include Lookupable
  
  has_paper_trail

  def values(provider_id)
    model.where(provider_id: provider_id).order(value_column_name)
  end

  def add_value(data, provider_id)
    data_config = {
      "#{value_column_name}": data[:value]
    }
    
    data_config["#{code_column_name}"] = data[:code] if code_column_name.present?
    data_config["#{description_column_name}"] = data[:description] if description_column_name.present?

    item = model.new(data_config) 
    item.provider_id = provider_id

    item.save

    item
  end

  def update_value(model_id, new_data)
    item = model.find_by_id(model_id)
    if item
      data_config = {
        "#{value_column_name}": new_data[:value]
      }
      
      data_config["#{code_column_name}"] = new_data[:code] if code_column_name.present?
      data_config["#{description_column_name}"] = new_data[:description] if description_column_name.present?

      item.assign_attributes(data_config)

      item.save
    end

    item
  end

  def destroy_value(model_id)
    item = model.find_by_id(model_id)
    item.destroy if item

    item
  end
end
