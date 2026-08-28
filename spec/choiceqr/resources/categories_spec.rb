require "spec_helper"

RSpec.describe ChoiceQR::Resources::Categories do
  let(:client) { build_client }
  let(:category_payload) { { "_id" => "1", "name" => "Hot", "section" => "sec1" } }

  describe "#list" do
    it "GETs categories scoped to a section" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/categories/list/sec1")
             .to_return(status: 200, body: json([category_payload]), headers: api_headers)

      categories = client.categories.list("sec1")
      expect(stub).to have_been_requested.once
      expect(categories.first.name).to eq("Hot")
    end
  end

  describe "#get" do
    it "GETs a single category by id" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/categories/1")
             .to_return(status: 200, body: json(category_payload), headers: api_headers)

      expect(client.categories.get("1").name).to eq("Hot")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#create" do
    it "POSTs the section and name" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/categories")
             .with(body: hash_including("name" => "Hot", "section" => "sec1"))
             .to_return(status: 201, body: json(category_payload), headers: api_headers)

      client.categories.create(name: "Hot", section: "sec1")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update" do
    it "PUTs and returns true" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/categories/1")
             .to_return(status: 204, body: "", headers: {})

      expect(client.categories.update("1", name: "Cold")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#set_position" do
    it "POSTs the ordered ids scoped to the section" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/categories/sec1/position/bulk")
             .with(body: %w[a b])
             .to_return(status: 204, body: "", headers: {})

      expect(client.categories.set_position("sec1", %w[a b])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/menu/en/categories/1").to_return(status: 204, body: "", headers: {})

      expect(client.categories.delete("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
