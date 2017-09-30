// JS for modal handling trip cancellation reason inputs
// takes a jQuery selector identifying the trip result reason modal div,
// and an array of codes (id #s) to consider asking for reason
function TripResultHelper(modalSelector, reasonNeededCodes) {
  this.modal = $(modalSelector);
  this.modalInput = this.modal.find('.result-reason-text');
  this.reasonNeededCodes = reasonNeededCodes;
}

TripResultHelper.prototype = {

  // returns true/false if integer corresponds to a cancellation code
  isReasonNeeded: function(code) {
    return this.reasonNeededCodes.includes(parseInt(code));
  },

  // Shows the modal
  showModal: function() {
    this.modal.modal('show');
  },

  // Prepares the modal. Takes a resultReason (string), isCancel (boolean),
  // and a hash of callback keys and functions.
  prepareModal: function(resultReason, isCancel, callbacks) {
    
    // Show and hide appropriate divs for result code
    if(isCancel) {
      this.modal.find('.cancel-code').removeClass('hidden');
      this.modal.find('.non-cancel-code').addClass('hidden');
    } else {
      this.modal.find('.non-cancel-code').removeClass('hidden');
      this.modal.find('.cancel-code').addClass('hidden');
    }

    // Update modal input to existing value of reason result
    this.modalInput.val(resultReason);

    // Set up modal response buttons with the callback functions
    var modal = this.modal;
    modal.find('.btn').addClass('hidden');
    $.each(callbacks, function(label, callback) {
      modal.find('.' + label + '-result-reason.btn')
      .off("click")
      .removeClass('hidden')
      .click(function() {
        callback();
      });
    });

  }

}
