require "spec_helper"

RSpec.describe ChoiceQR::Resources::Pack do
  let(:client) { build_client }
  let(:pack_payload) { { "_id" => "1", "name" => "Lunch set", "price" => 1000 } }

  describe "#list" do
    it "GETs the pack list" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/pack/list")
             .to_return(status: 200, body: json([pack_payload]), headers: api_headers)

      packs = client.pack.list
      expect(stub).to have_been_requested.once
      expect(packs.first.name).to eq("Lunch set")
    end
  end

  describe "#get" do
    it "GETs a single pack by id" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/pack/1")
             .to_return(status: 200, body: json(pack_payload), headers: api_headers)

      expect(client.pack.get("1").name).to eq("Lunch set")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#create" do
    it "preserves a leading underscore on nested category _id references" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/pack")
             .with(body: hash_including(
               "name" => "Lunch set",
               "categories" => [{ "_id" => "cat1", "posID" => "5" }]
             ))
             .to_return(status: 201, body: json(pack_payload), headers: api_headers)

      client.pack.create(name: "Lunch set", price: 1000, categories: [{ _id: "cat1", pos_id: "5" }])
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update" do
    it "PUTs and returns true" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/pack/1").to_return(status: 204, body: "", headers: {})

      expect(client.pack.update("1", name: "Dinner set", price: 1500)).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/menu/en/pack/1").to_return(status: 204, body: "", headers: {})

      expect(client.pack.delete("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
