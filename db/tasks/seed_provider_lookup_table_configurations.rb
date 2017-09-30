[
  {
    name: 'funding_sources',
    caption: 'Funding Source',
    value_column_name: 'name'
  },
  {
    name: 'vehicle_warranty_templates',
    caption: 'Vehicle Warranty',
    value_column_name: 'name'
  },
  {
    name: 'ada_questions',
    caption: 'ADA Eligibility Question (yes/no)',
    value_column_name: 'name'
  }
].each do | config_data|
  config = ProviderLookupTable.find_by(name: config_data[:name])
  if config 
    config.update_attributes(config_data)
  else
    ProviderLookupTable.create(config_data)
  end
end