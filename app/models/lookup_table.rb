class LookupTable < ActiveRecord::Base  
  include Lookupable

  has_paper_trail

  def values
    return [] unless model.present?

    if model.column_names.include? "provider_id"
      model.where(provider_id: nil).order(value_column_name)
    else
      model.all.order(value_column_name)
    end
  end

  def add_value(data)
    if add_value_allowed
      data_config = {
        "#{value_column_name}": data[:value]
      }
      
      data_config["#{code_column_name}"] = data[:code] if code_column_name.present?
      data_config["#{description_column_name}"] = data[:description] if description_column_name.present?

      item = model.new(data_config) 
      item.save

      item
    else
      nil
    end
  end

  def update_value(model_id, new_data)
    item = model.find_by_id(model_id)
    if item && edit_value_allowed
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
    item.destroy if item && delete_value_allowed

    item
  end

  def hide_value(model_id, provider_id)
    HiddenLookupTableValue.hide_value(name, provider_id, model_id)
  end

  def show_value(model_id, provider_id)
    HiddenLookupTableValue.show_value(name, provider_id, model_id)
  end
end
