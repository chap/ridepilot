require "rails_helper"

RSpec.describe AddressesController, type: :routing do
  describe "routing" do

    it "does not route to #index" do
      expect(:get => "/addresses").to_not route_to("addresses#index")
    end

    it "does not route to #new" do
      expect(:get => "/addresses/new").to_not route_to("addresses#new")
    end

    it "does not route to #show" do
      expect(:get => "/addresses/1").to_not route_to("addresses#show", :id => "1")
    end

    it "does not route to #edit" do
      expect(:get => "/addresses/1/edit").to_not route_to("addresses#edit", :id => "1")
    end

    it "does not route to #create" do
      expect(:post => "/addresses").to_not route_to("addresses#create")
    end

    it "does not route to #update" do
      expect(:put => "/addresses/1").to_not route_to("addresses#update", :id => "1")
    end

    it "does not route to #destroy" do
      expect(:delete => "/addresses/1").to_not route_to("addresses#destroy", :id => "1")
    end

    it "routes to #trippable_autocomplete" do
      expect(:get => "/trip_address_autocomplete").to route_to("addresses#trippable_autocomplete")
    end

  end
end
