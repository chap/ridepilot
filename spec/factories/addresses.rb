require 'faker'

FactoryGirl.define do
  factory :address do
    name { Faker::Lorem.words(2).join(' ') }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    state "OR"
  end

  factory :user_address, parent: :address, class: UserAddress
  
  factory :driver_address, parent: :address, class: DriverAddress

  factory :geocoded_address, parent: :address, class: GeocodedAddress do 
    the_geom RGeo::Geographic.spherical_factory(srid: 4326).point(100, 30)
  end

  factory :customer_common_address, parent: :address, class: CustomerCommonAddress

  factory :provider_common_address, parent: :address, class: ProviderCommonAddress do 
    address_group
  end
end
