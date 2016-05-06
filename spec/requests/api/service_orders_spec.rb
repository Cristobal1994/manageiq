RSpec.describe "service orders API" do
  it "can list all service orders" do
    service_order = FactoryGirl.create(:shopping_cart, :user => @user)
    api_basic_authorize collection_action_identifier(:service_orders, :read, :get)

    run_get service_orders_url

    expect_request_success
    expect_result_resources_to_include_hrefs("resources", [service_orders_url(service_order.id)])
  end

  it "won't show another user's service orders" do
    shopping_cart_for_user = FactoryGirl.create(:shopping_cart, :user => @user)
    _shopping_cart_for_some_other_user = FactoryGirl.create(:shopping_cart)
    api_basic_authorize collection_action_identifier(:service_orders, :read, :get)

    run_get service_orders_url

    expected = {
      "count"     => 2,
      "subcount"  => 1,
      "resources" => [{"href" => a_string_matching(service_orders_url(shopping_cart_for_user.id))}]
    }
    expect(response).to have_http_status(:ok)
    expect(response_hash).to include(expected)
  end

  it "can create a service order" do
    api_basic_authorize collection_action_identifier(:service_orders, :create)

    expect do
      run_post service_orders_url, :name => "service order", :state => "wish"
    end.to change(ServiceOrder, :count).by(1)

    expect_request_success
  end

  it "can create multiple service orders" do
    api_basic_authorize collection_action_identifier(:service_orders, :create)

    expect do
      run_post(service_orders_url,
               :action => "create", :resources => [{:name => "service order 1", :state => "wish"},
                                                   {:name => "service order 2", :state => "wish"}])
    end.to change(ServiceOrder, :count).by(2)
    expect_request_success
  end

  specify "the default state for a service order is 'cart'" do
    api_basic_authorize collection_action_identifier(:service_orders, :create)

    run_post(service_orders_url, :name => "shopping cart")

    expect(response_hash).to include("results" => [a_hash_including("state" => ServiceOrder::STATE_CART)])
  end

  specify "a service order cannot be created in the 'ordered' state" do
    api_basic_authorize collection_action_identifier(:service_orders, :create)

    expect do
      run_post(service_orders_url, :name => "service order", :state => ServiceOrder::STATE_ORDERED)
    end.not_to change(ServiceOrder, :count)

    expect(response).to have_http_status(:bad_request)
    expect(response_hash).to include("error" => a_hash_including("message" => /can't create an ordered service order/i))
  end

  it "can read a service order" do
    service_order = FactoryGirl.create(:service_order, :user => @user)
    api_basic_authorize action_identifier(:service_orders, :read, :resource_actions, :get)

    run_get service_orders_url(service_order.id)

    expect_result_to_match_hash(response_hash, "name" => service_order.name, "state" => service_order.state)
    expect_request_success
  end

  it "can show the shopping cart" do
    shopping_cart = FactoryGirl.create(:shopping_cart, :user => @user)
    api_basic_authorize action_identifier(:service_orders, :read, :resource_actions, :get)

    run_get service_orders_url("cart")

    expect(response).to have_http_status(:ok)
    expect(response_hash).to include("id"   => shopping_cart.id,
                                     "href" => a_string_matching(service_orders_url(shopping_cart.id)))
  end

  it "returns an empty response when there is no shopping cart" do
    api_basic_authorize action_identifier(:service_orders, :read, :resource_actions, :get)

    run_get service_orders_url("cart")

    expect(response).to have_http_status(:not_found)
    expect(response_hash).to include("error" => a_hash_including("kind"    => "not_found",
                                                                 "message" => /Couldn't find ServiceOrder/))
  end

  it "can update a service order" do
    service_order = FactoryGirl.create(:service_order, :name => "old name", :user => @user)
    api_basic_authorize action_identifier(:service_orders, :edit)

    run_post service_orders_url(service_order.id), :action => "edit", :resource => {:name => "new name"}

    expect_result_to_match_hash(response_hash, "name" => "new name")
    expect_request_success
  end

  it "can update multiple service orders" do
    service_order_1 = FactoryGirl.create(:service_order, :user => @user, :name => "old name 1")
    service_order_2 = FactoryGirl.create(:service_order, :user => @user, :name => "old name 2")
    api_basic_authorize collection_action_identifier(:service_orders, :edit)

    run_post(service_orders_url,
             :action => "edit", :resources => [{:id => service_order_1.id, :name => "new name 1"},
                                               {:id => service_order_2.id, :name => "new name 2"}])

    expect_results_to_match_hash("results", [{"name" => "new name 1"}, {"name" => "new name 2"}])
    expect_request_success
  end

  it "can delete a service order" do
    service_order = FactoryGirl.create(:service_order, :user => @user)
    api_basic_authorize action_identifier(:service_orders, :delete, :resource_actions, :delete)

    expect do
      run_delete service_orders_url(service_order.id)
    end.to change(ServiceOrder, :count).by(-1)
    expect_request_success_with_no_content
  end

  it "can delete a service order through POST" do
    service_order = FactoryGirl.create(:service_order, :user => @user)
    api_basic_authorize action_identifier(:service_orders, :delete)

    expect do
      run_post service_orders_url(service_order.id), :action => "delete"
    end.to change(ServiceOrder, :count).by(-1)
    expect_request_success
  end

  it "can delete multiple service orders" do
    service_order_1 = FactoryGirl.create(:service_order, :user => @user, :name => "old name")
    service_order_2 = FactoryGirl.create(:service_order, :user => @user, :name => "old name")
    api_basic_authorize collection_action_identifier(:service_orders, :delete)

    expect do
      run_post(service_orders_url,
               :action => "delete", :resources => [{:id => service_order_1.id},
                                                   {:id => service_order_2.id}])
    end.to change(ServiceOrder, :count).by(-2)
    expect_request_success
  end
end
