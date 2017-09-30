require 'open-uri'

class AddressesController < ApplicationController
  load_resource :only => [:edit, :update, :destroy]
  authorize_resource

  # provider & customer common addresses
  def trippable_autocomplete
    term = parse_search_term

    #three ways to match:
    #- name
    #- building name
    #- substring of textified address (split at comma into address,
    #  city/state/zip)

    address, city_state_zip = term.split(",")
    address.strip!
    if city_state_zip
      city_state_zip.strip!
    else
      city_state_zip = ''
    end

    arel_table = Address.arel_table

    if params[:customer_id].present? 
      customer = Customer.find_by_id(params[:customer_id])
      base_arel = (arel_table[:customer_id].in(customer.id).and(arel_table[:type].eq('CustomerCommonAddress')))
      if customer
        base_arel = base_arel.or(arel_table[:provider_id].in(customer.authorized_provider_ids).and(arel_table[:type].eq('ProviderCommonAddress')))
      end
    else
      base_arel = arel_table[:provider_id].eq(current_provider_id).and(arel_table[:type].eq('ProviderCommonAddress'))
    end

    addresses = Address.where(base_arel.to_sql)
      .where('inactive is NULL or inactive != ?', true)
      .where.not(the_geom: nil)
      .where(["((LOWER(address) like '%' || ? || '%' ) and  (city || ', ' || state || ' ' || zip like ? || '%')) or LOWER(building_name) like '%' || ? || '%' or LOWER(name) like '%' || ? || '%' ", address, city_state_zip, term, term])

    if params[:exclude].present?
      addresses = addresses.where.not(id: params[:exclude].split(','))
    end

    if addresses.size > 0
      #there are some existing addresses
      address_json = addresses.map { |address| address.json }
    end

    respond_to do |format|
      format.json { render json: address_json || [] }
    end
  end

  def autocomplete_public
    term = parse_search_term

    address_json = GeocodingService.new(term, current_provider).execute

    render :json => address_json
  end


  def validate_customer_specific
    the_geom       = params[:lat].to_s.size > 0 ? RGeo::Geographic.spherical_factory(srid: 4326).point(params[:lon].to_f, params[:lat].to_f) : nil
    prefix         = params['prefix'] || ""
    address_params = {}

    # Some kind of faux strong parameters...
    for param in ['name', 'building_name', 'address', 'city', 'state', 'zip', 'phone_number', 'in_district', 'trip_purpose_id', 'notes']
      address_params[param] = params[prefix][param]
    end
    
    address_params[:the_geom]    = the_geom if the_geom

    if params[:address_id].present?
      address = CustomerCommonAddress.find_by_id(params[:address_id])
      address.attributes = address_params
    else
      address_params[:provider_id] = current_provider_id
      address = CustomerCommonAddress.new(address_params)
    end

    if address.valid?
      label = address.address_text
      render :json => {
        success: true,
        prefix: prefix,
        address_text: label,
        attributes: address.attributes.merge({label: label})
      }
    else
      errors = address.errors.messages
      errors[:prefix] = prefix
      render :json => errors
    end
  end

  private

  def parse_search_term
    term = params['term'].downcase.strip

    #clean up address
    term.gsub!(' apt ', ' #')
    term.gsub!(' apartment ', ' #')
    term.gsub!(' suite ', ' #')

    term.gsub!(' n ', ' north ')
    term.gsub!(' ne ', ' northeast ')
    term.gsub!(' e ', ' east ')
    term.gsub!(' se ', ' southeast ')
    term.gsub!(' s ', ' south ')
    term.gsub!(' sw ', ' southwest ')
    term.gsub!(' w ', ' west ')
    term.gsub!(' nw ', ' northwest ')

    term.gsub!(' ave,', 'avenue,')
    term.gsub!(' dr,', 'drive,')
    term.gsub!(' st,', 'street,')
    term.gsub!(' blvd,', 'boulevard,')
    term.gsub!(' pkwy,', 'parkway,')

    term
  end
end
