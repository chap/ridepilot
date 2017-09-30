// Helper for checking if a trip is double-booked

function DoubleBookedTripsHelper(params) {
  params = params || {};
  this.url = params.url;
  this.tableRowHtml = params.tableRowHtml;
  this.form = params.form;
  this.modal = params.modal;
  this.table = params.table;
}

DoubleBookedTripsHelper.prototype = {
  
  checkDoubleBooked: function(requestBody, callback) {
    $.ajax({
      type: 'POST',
      url: this.url,
      data: requestBody,
      dataType: 'json'
    }).done(callback);
  },
  
  requestBodyFromForm: function(tripId) {
    return {
      trip: {
       id: tripId || null,
       customer_id: this.form.find('.trip-customer-id').val(),
       date: this.form.find('input#trip_date').val()
      }
    }
  },
  
  populateTable: function(trips) {
    this.table.find('.header-row').nextAll().remove(); // Clear all rows
    var dbh = this;
    trips.forEach(function(trip) {
      dbh.table.append(dbh.tableRowHtml);
      var row = dbh.table.find('.double-booked-trip-row').last();
      row.find('.trip-pickup-time').text(trip.pickup_time);
      row.find('.trip-pickup-address').text(trip.pickup_address);      
      row.find('.trip-appointment-time').text(trip.appointment_time);
      row.find('.trip-dropoff-address').text(trip.dropoff_address);
    });
  },
  
  showModal: function() {
    this.modal.modal("show");
  }
  
}
