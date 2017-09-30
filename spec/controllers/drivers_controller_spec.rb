require "rails_helper"

RSpec.describe DriversController, type: :controller do
  login_admin_as_current_user
  
  # This should return the minimal set of attributes required to create a valid
  # Driver. As you add validations to Driver, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:driver, 
      name: 'test drivers',
      phone_number: '(801)4567890', 
      user_id: create(:user, :current_provider => @current_user.current_provider).id,
      address_attributes: attributes_for(:address)
      )
  }

  let(:invalid_attributes) {
    attributes_for(:driver, :phone_number => nil)
  }

  describe "GET #index" do
    it "assigns all drivers for the current provider as @drivers" do
      driver_1 = create(:driver, :provider => @current_user.current_provider, :active => true)
      driver_2 = create(:driver, :active => true)
      get :index, {}
      expect(assigns(:drivers)).to match([driver_1])
    end

    it "default to only active drivers" do
      active_driver = create(:driver, :provider => @current_user.current_provider, :active => true)
      inactive_driver = create(:driver, :provider => @current_user.current_provider, :active => false)
      get :index, {}
      expect(assigns(:drivers)).to match([active_driver])
    end

    it "gets all drivers with show_inactive param as true" do
      active_driver = create(:driver, :provider => @current_user.current_provider, :active => true)
      inactive_driver = create(:driver, :provider => @current_user.current_provider, :active => false)
      get :index, {show_inactive: 'true'}
      expect(assigns(:drivers)).to match_array([active_driver, inactive_driver])
    end
  end

  describe "GET #show" do
    it "assigns the requested driver as @driver" do
      driver = create(:driver, :provider => @current_user.current_provider)
      get :show, {:id => driver.to_param}
      expect(assigns(:driver)).to eq(driver)
    end

    it "sets @readonly to true" do
      driver = create(:driver, :provider => @current_user.current_provider)
      get :show, {:id => driver.to_param}
      expect(assigns(:readonly)).to be_truthy
    end
  end

  describe "GET #new" do
    it "assigns a new driver as @driver" do
      get :new, {}
      expect(assigns(:driver)).to be_a_new(Driver)
    end
  end

  describe "GET #edit" do
    it "assigns the requested driver as @driver" do
      driver = create(:driver, :provider => @current_user.current_provider)
      get :edit, {:id => driver.to_param}
      expect(assigns(:driver)).to eq(driver)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Driver" do
        expect {
          post :create, {:driver => valid_attributes}
        }.to change(Driver, :count).by(1)
      end

      it "assigns a newly created driver as @driver" do
        post :create, {:driver => valid_attributes}
        expect(assigns(:driver)).to be_a(Driver)
        expect(assigns(:driver)).to be_persisted
      end

      it "redirects to the new driver" do
        post :create, {:driver => valid_attributes}
        expect(response).to redirect_to(Driver.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved driver as @driver" do
        post :create, {:driver => invalid_attributes}
        expect(assigns(:driver)).to be_a_new(Driver)
      end

      it "re-renders the 'new' template" do
        post :create, {:driver => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          :active => false,
          :paid => false,
          :phone_number => "8881234567",
          :user => create(:user, :current_provider => @current_user.current_provider).id,
        }
      }

      it "updates the requested driver" do
        driver = create(:driver, :provider => @current_user.current_provider, :phone_number => '8884567890')
        expect {
          put :update, {:id => driver.to_param, :driver => new_attributes}
        }.to change { driver.reload.phone_number }.from("8884567890").to("8881234567")
      end

      it "assigns the requested driver as @driver" do
        driver = create(:driver, :provider => @current_user.current_provider)
        put :update, {:id => driver.to_param, :driver => new_attributes}
        expect(assigns(:driver)).to eq(driver)
      end

      it "redirects to the driver" do
        driver = create(:driver, :provider => @current_user.current_provider)
        put :update, {:id => driver.to_param, :driver => new_attributes}
        expect(response).to redirect_to(driver)
      end
    end

    context "with invalid params" do
      it "assigns the driver as @driver" do
        driver = create(:driver, :provider => @current_user.current_provider)
        put :update, {:id => driver.to_param, :driver => invalid_attributes}
        expect(assigns(:driver)).to eq(driver)
      end

      it "re-renders the 'edit' template" do
        driver = create(:driver, :provider => @current_user.current_provider)
        put :update, {:id => driver.to_param, :driver => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested driver" do
      driver = create(:driver, :provider => @current_user.current_provider)
      expect {
        delete :destroy, {:id => driver.to_param}
      }.to change(Driver, :count).by(-1)
    end

    it "redirects to the drivers list" do
      driver = create(:driver, :provider => @current_user.current_provider)
      delete :destroy, {:id => driver.to_param}
      expect(response).to redirect_to(drivers_url)
    end
  end
end
