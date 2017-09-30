require "rails_helper"

RSpec.describe AddressesController, type: :routing do
  describe "routing" do

    it "does not route to #index" do
      expect(:get => "/provider_common_addresses").to_not route_to("provider_common_addresses#index")
    end

    it "does not route to #new" do
      expect(:get => "/provider_common_addresses/new").to_not route_to("provider_common_addresses#new")
    end

    it "does not route to #show" do
      expect(:get => "/provider_common_addresses/1").to_not route_to("provider_common_addresses#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/provider_common_addresses/1/edit").to route_to("provider_common_addresses#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/provider_common_addresses").to route_to("provider_common_addresses#create")
    end

    it "routes to #update" do
      expect(:put => "/provider_common_addresses/1").to route_to("provider_common_addresses#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/provider_common_addresses/1").to route_to("provider_common_addresses#destroy", :id => "1")
    end

    it "routes to #autocomplete" do
      expect(:get => "/provider_common_addresses/autocomplete").to route_to("provider_common_addresses#autocomplete")
    end

    it "routes to #search" do
      expect(:get => "/provider_common_addresses/search").to route_to("provider_common_addresses#search")
    end

  end
end
