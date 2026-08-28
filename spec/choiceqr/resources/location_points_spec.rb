require "spec_helper"

RSpec.describe ChoiceQR::Resources::LocationPoints do
  let(:client) { build_client }
  let(:point_payload) { { "_id" => "1", "name" => "Table 4", "area" => "area1" } }

  describe "#list" do
    it "GETs points scoped to an area" do
      stub = stub_request(:get, "#{API_BASE}/location/en/points/list/area1")
             .to_return(status: 200, body: json([point_payload]), headers: api_headers)

      points = client.location_points.list("area1")
      expect(stub).to have_been_requested.once
      expect(points.first.name).to eq("Table 4")
    end
  end

  describe "#get" do
    it "GETs a single point by id" do
      stub = stub_request(:get, "#{API_BASE}/location/en/points/1")
             .to_return(status: 200, body: json(point_payload), headers: api_headers)

      expect(client.location_points.get("1").name).to eq("Table 4")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#create" do
    it "POSTs the point payload" do
      stub = stub_request(:post, "#{API_BASE}/location/en/points")
             .with(body: hash_including("name" => "Table 4", "area" => "area1"))
             .to_return(status: 201, body: json(point_payload), headers: api_headers)

      client.location_points.create(name: "Table 4", area: "area1")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update" do
    it "PUTs and returns true" do
      stub = stub_request(:put, "#{API_BASE}/location/en/points/1").to_return(status: 204, body: "", headers: {})

      expect(client.location_points.update("1", name: "Table 5")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/location/en/points/1").to_return(status: 204, body: "", headers: {})

      expect(client.location_points.delete("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
