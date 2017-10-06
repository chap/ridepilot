// initialize a place picker to query 1-click place datatable and google places
function init_place_picker(dom_selector, query_bounds, query_restrictions) {
  var saved_places = new Bloodhound({
    datumTokenizer: function(d) {
     return  Bloodhound.tokenizers.whitespace(d.value);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
      url: '/trip_address_autocomplete.json?',
      rateLimitWait: 600,
      replace: function(url, query) {
        url = url + '&customer_id=' + $("input.trip-customer-id").val() + '&term=' + query;
        return url;
      }
    },
    limit: 10
  });

  saved_places.initialize();

  var autocomplete_service_config = {};
  if (query_bounds) {
    autocomplete_service_config.bounds = new google.maps.LatLngBounds(
      new google.maps.LatLng(query_bounds.min_lat,query_bounds.min_lon),
      new google.maps.LatLng(query_bounds.max_lat,query_bounds.max_lon));
  }
  if (query_restrictions) {
    autocomplete_service_config.componentRestrictions = query_restrictions;
  } else {
    autocomplete_service_config.types = ['geocode'];
    autocomplete_service_config.componentRestrictions = { country: 'us' };
  }
  var google_place_picker = new AddressPicker({
    autocompleteService: autocomplete_service_config
  });

  $(dom_selector).typeahead({
    highlight: true
  },
    {
      name: 'saved_places',
      displayKey: "label",
      source: saved_places.ttAdapter(),
      templates: {
        header: '<h4>Saved Addresses</h4>',
        suggestion: Handlebars.compile([
          '<a>{{label}}</a>'
        ].join(''))
      }
    },
    {
      name: 'google_places',
      displayKey: "description",
      source: google_place_picker.ttAdapter(),
      templates: {
        header: '<h4>Google Suggestions</h4>',
        suggestion: Handlebars.compile([
          '<a>{{description}}</a>'
        ].join(''))
      }
    });
}

var google_place_service = new google.maps.places.PlacesService(document.createElement('div'));
function process_google_address(addr, type) {
  google_place_service.getDetails({
    placeId: addr.place_id
  }, function(place, status) {
    if (status === google.maps.places.PlacesServiceStatus.OK) {
      $('input.trip_' + type + '_google_address').val(JSON.stringify(googlePlaceParser(place)));
    } else {
      return google_place_service.getDetails({
        reference: addr.reference
      }, function(new_place, status) {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
          $('input.trip_' + type + '_google_address').val(JSON.stringify(googlePlaceParser(new_place)));
        } else {
          return console.log("No match found for: " + addr.name);
        }
      });
    }
  });
}

$(function() {
  $('#pickup_address').on('input', function() {
    $('input.trip_pickup_address_id').val('');
    $('input.trip_pickup_google_address').val('');
    $('#pickup_address_notes').val('');
  });
  
  $('#pickup_address').on('typeahead:selected', function(e, addr, data) {
    if(data == 'saved_places') {
      $('input.trip_pickup_address_id').val(addr.id);
      $('#pickup_address_notes').val(addr.notes);
      // TODO: insert saved place's notes to Trip Notes field if applicable
    } else if (data == 'google_places') {
      process_google_address(addr, 'pickup');
    }
  });

  $('#dropoff_address').on('input', function() {
    $('input.trip_dropoff_address_id').val('');
    $('input.trip_dropoff_google_address').val('');
    $('#dropoff_address_notes').val('');
  });
  $('#dropoff_address').on('typeahead:selected', function(e, addr, data) {
    $('input.trip_dropoff_address_id').val('');
    $('input.trip_dropoff_google_address').val('');
    if(data == 'saved_places') {
      $('input.trip_dropoff_address_id').val(addr.id);
      $('.trip_purpose_id').val(addr.trip_purpose_id);
      $('#dropoff_address_notes').val(addr.notes);
    } else if (data == 'google_places') {
      process_google_address(addr, 'dropoff');
    }
  });
});
