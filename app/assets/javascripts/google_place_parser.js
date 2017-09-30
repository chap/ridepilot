// This is a simple utility function to parse a google place object to
//    Ridepilot address data which only cares following address_component types: 
//      street_address, locality, administrative_area_level_1, postal_code, 
//    and location (lat, lng)
function googlePlaceParser(place) {
  if(!place) {
    return {};
  }

  var location = place.geometry.location;
  var addrData = {
    lat: location.lat(),
    lon: location.lng()
  };

  var addrComponents = place.address_components || [];
  var route = null;
  addrComponents.forEach(function(comp) {
    if(comp.types.indexOf('street_number') >= 0) {
      addrData.street_number = comp.long_name;
    } else if(comp.types.indexOf('route') >= 0) {
      route = comp.long_name;
    } else if(comp.types.indexOf('street_address') >= 0) {
      addrData.address = comp.long_name;
    } else if(
      comp.types.indexOf('locality') >= 0 || 
      comp.types.indexOf('administrative_area_level_3') >= 0
      ) {
      addrData.city = comp.long_name;
    } else if(comp.types.indexOf('administrative_area_level_1') >= 0) {
      addrData.state = comp.short_name;
    } else if(comp.types.indexOf('postal_code') >= 0) {
      addrData.zip = comp.long_name;
    } 
  });

  if(!addrData.street_address) {
    if(addrData.street_number && route) {
      addrData.address = addrData.street_number + " " + route;
    }
    else if(place.name) {
      addrData.address = place.name;
    }
  }
  return addrData;
}