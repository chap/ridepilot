class TempAddress < Address 
  FORM_PARAMS = ['address', 'city', 'state', 'zip', 'notes']

  def self.parse_api_params(address_params)
    address_data = GooglePlaceParser.new(address_params[:address]).parse || {}

    existing_addr = TempAddress.search_existing_address({
      address: address_data[:address],
      city: address_data[:city],
      state: address_data[:state],
      customer_id: address_params[:customer_id]
      })

    if !existing_addr
      TempAddress.new( address_data.merge({
        customer_id: address_params[:customer_id],
        trip_purpose_id: address_params[:trip_purpose_id],
        provider_id: address_params[:provider_id],
        name: address_params[:address_name],
        notes: address_params[:note],
        in_district: address_params[:in_district]
        }) )
    else
      existing_addr
    end
  end

  def self.search_existing_address(criteria)
    where(criteria).first
  end

  def self.allowable_params
    FORM_PARAMS
  end
end