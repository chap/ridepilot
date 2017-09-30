class GeocodedAddress < Address 
  validates :the_geom, presence: true
end