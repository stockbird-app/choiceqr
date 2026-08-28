require "spec_helper"

RSpec.describe ChoiceQR::Resources::Dishes do
  let(:client) { build_client }
  let(:dish_payload) { { "_id" => "1", "name" => "Cappuccino", "posID" => "5", "price" => 420 } }

  describe "#list" do
    it "GETs dishes scoped to a category" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/dishes/list/cat1")
             .to_return(status: 200, body: json([dish_payload]), headers: api_headers)

      dishes = client.dishes.list("cat1")
      expect(stub).to have_been_requested.once
      expect(dishes.first.name).to eq("Cappuccino")
    end
  end

  describe "#find_by_pos_id" do
    it "sends the posID query param (capitalized as the API expects)" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/dishes")
             .with(query: { "posID" => "5" })
             .to_return(status: 200, body: json(dish_payload), headers: api_headers)

      dish = client.dishes.find_by_pos_id("5")
      expect(stub).to have_been_requested.once
      expect(dish.pos_id).to eq("5")
    end
  end

  describe "#get" do
    it "GETs a single dish by id" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/dishes/1")
             .to_return(status: 200, body: json(dish_payload), headers: api_headers)

      expect(client.dishes.get("1").name).to eq("Cappuccino")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#create" do
    it "POSTs a camelCase body including price in cents" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/dishes")
             .with(body: hash_including("name" => "Cappuccino", "category" => "cat1", "price" => 420))
             .to_return(status: 201, body: json(dish_payload), headers: api_headers)

      client.dishes.create(name: "Cappuccino", category: "cat1", price: 420)
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update" do
    it "PUTs and returns true" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/dishes/1").to_return(status: 204, body: "", headers: {})

      expect(client.dishes.update("1", name: "Espresso", price: 350)).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#patch" do
    it "PATCHes only the given fields" do
      stub = stub_request(:patch, "#{API_BASE}/menu/en/dishes/1")
             .with(body: { "active" => false })
             .to_return(status: 204, body: "", headers: {})

      expect(client.dishes.patch("1", active: false)).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update_areas" do
    it "PUTs the areas sync body" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/dishes/1/areas")
             .with(body: { "takeaway" => true, "delivery" => false })
             .to_return(status: 204, body: "", headers: {})

      expect(client.dishes.update_areas("1", takeaway: true, delivery: false)).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#set_position" do
    it "POSTs the ordered ids scoped to the category" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/dishes/cat1/position/bulk")
             .with(body: %w[a b])
             .to_return(status: 204, body: "", headers: {})

      expect(client.dishes.set_position("cat1", %w[a b])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/menu/en/dishes/1").to_return(status: 204, body: "", headers: {})

      expect(client.dishes.delete("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
