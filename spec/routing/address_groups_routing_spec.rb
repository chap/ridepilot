require "rails_helper"

RSpec.describe AddressGroupsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/address_groups").to route_to("address_groups#index")
    end

    it "routes to #new" do
      expect(:get => "/address_groups/new").to route_to("address_groups#new")
    end

    it "routes to #show" do
      expect(:get => "/address_groups/1").to route_to("address_groups#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/address_groups/1/edit").to route_to("address_groups#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/address_groups").to route_to("address_groups#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/address_groups/1").to route_to("address_groups#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/address_groups/1").to route_to("address_groups#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/address_groups/1").to route_to("address_groups#destroy", :id => "1")
    end

  end
end
