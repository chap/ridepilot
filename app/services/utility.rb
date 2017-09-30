class Utility
  def parse_date(time_param)
    return if !time_param.present? 

    # this is to parse calendar params
    # will be deprecated after new calendar gets in
    if time_param.is_a?(Date) 
      time = time_param
    elsif time_param.is_a?(DateTime)
      time = time_param.to_date
    elsif time_param.to_i.to_s == time_param.to_s
      time = Time.zone.at(time_param.to_i)
    else
      time = Date.strptime(time_param, '%d-%b-%Y %a') rescue nil
    end

    time.to_date.in_time_zone if time
  end

  def get_provider_bounds(provider)
    if provider && provider.region_nw_corner && provider.region_se_corner
      min_lon = provider.region_nw_corner.x 
      max_lon = provider.region_se_corner.x 
      min_lat = provider.region_se_corner.y 
      max_lat = provider.region_nw_corner.y 
    elsif GOOGLE_MAP_DEFAULTS && GOOGLE_MAP_DEFAULTS[:bounds]
      min_lon = GOOGLE_MAP_DEFAULTS[:bounds][:west]
      max_lon = GOOGLE_MAP_DEFAULTS[:bounds][:east]
      min_lat = GOOGLE_MAP_DEFAULTS[:bounds][:south]
      max_lat = GOOGLE_MAP_DEFAULTS[:bounds][:north]
    end

    {
      min_lat: min_lat,
      max_lat: max_lat,
      min_lon: min_lon,
      max_lon: max_lon
    } if min_lat && max_lat && min_lon && max_lon
  end

  def phone_number_valid?(phone_number)
    us_phony = Phony['1'] # US phone validation

    norm_number = us_phony.normalize(phone_number.to_s)
    us_phony.plausible? norm_number
  end
end