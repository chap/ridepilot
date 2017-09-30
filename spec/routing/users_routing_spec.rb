require "rails_helper"

RSpec.describe UsersController, type: :routing do
  describe "routing" do
    # NOTE we're only testing the non-Devise routes

    it "routes to #new_user" do
      expect(:get => "/providers/1/users/new_user").to route_to("action"=>"new_user", "controller"=>"users", "provider_id"=>"1")
    end

    it "routes to #create_user" do
      expect(:post => "/providers/1/users/create_user").to route_to("action"=>"create_user", "controller"=>"users", "provider_id"=>"1")
    end

    it "routes to #show_change_password" do
      expect(:get => "/show_change_password").to route_to("users#show_change_password")
    end

    it "routes to #change_password" do
      expect(:patch => "/change_password").to route_to("users#change_password")
    end

    it "routes to #show_change_expiration" do
      expect(:get => "/show_change_expiration").to route_to("users#show_change_expiration")
    end

    it "routes to #change_expiration" do
      expect(:patch => "/change_expiration").to route_to("users#change_expiration")
    end

    it "routes to #change_provider" do
      expect(:post => "/change_provider").to route_to("users#change_provider")
    end

    it "routes to #check_session" do
      expect(:get => "/check_session").to route_to("users#check_session")
    end

    it "routes to #touch_session" do
      expect(:get => "/touch_session").to route_to("users#touch_session")
    end
  end
end
