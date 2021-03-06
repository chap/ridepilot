TRIP_RESULT_CODES = {
  "COMP"  => "Complete",    # the trip was (as far as we know) completed
  "NS"    => "No-show",     # the customer did not show up for the trip
  "MT"    => "Missed Trip", # the customer missed the trip
  "CANC"  => "Cancelled",   # the trip was cancelled by the customer
  "LTCANC"  => "Late Cancel",   # the trip was cancelled by the customer (late)
  "SDCANC"  => "Same Day Cancel",   # the trip was cancelled by the customer (same day)
  "TD"    => "Turned Down", # the provider told the customer that it could not provide the trip
  "UNMET" => "Unmet Need"   # a trip that was outside of the service parameters (too early, too late, too far, etc).
}
  
TRIP_RESULT_CODES.each do |code, text|
  result = TripResult.where(code: code).first_or_create.update(name: text)
end