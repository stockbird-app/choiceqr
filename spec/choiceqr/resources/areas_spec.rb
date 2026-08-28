require "spec_helper"

RSpec.describe ChoiceQR::Resources::Areas do
  let(:client) { build_client }
  let(:area_payload) { { "_id" => "1", "name" => "Terrace", "type" => "simple" } }

  describe "#list" do
    it "GETs the areas list" do
      stub = stub_request(:get, "#{API_BASE}/location/en/areas/list")
             .to_return(status: 200, body: json([area_payload]), headers: api_headers)

      areas = client.areas.list
      expect(stub).to have_been_requested.once
      expect(areas.first.name).to eq("Terrace")
    end
  end

  describe "#get" do
    it "GETs a single area by id" do
      stub = stub_request(:get, "#{API_BASE}/location/en/areas/1")
             .to_return(status: 200, body: json(area_payload), headers: api_headers)

      expect(client.areas.get("1").name).to eq("Terrace")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#get_by_type" do
    it "GETs the area for a given type" do
      stub = stub_request(:get, "#{API_BASE}/location/en/areas/by-type/takeaway")
             .to_return(status: 200, body: json(area_payload.merge("type" => "takeaway")), headers: api_headers)

      expect(client.areas.get_by_type("takeaway").type).to eq("takeaway")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#create" do
    it "POSTs the area payload with nested payment methods" do
      stub = stub_request(:post, "#{API_BASE}/location/en/areas")
             .with(body: hash_including(
               "name" => "Terrace",
               "paymentMethods" => { "cash" => true, "card" => true }
             ))
             .to_return(status: 201, body: json(area_payload), headers: api_headers)

      client.areas.create(name: "Terrace", payment_methods: { cash: true, card: true })
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update" do
    it "PUTs and returns true" do
      stub = stub_request(:put, "#{API_BASE}/location/en/areas/1").to_return(status: 204, body: "", headers: {})

      expect(client.areas.update("1", name: "Garden")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/location/en/areas/1").to_return(status: 204, body: "", headers: {})

      expect(client.areas.delete("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
