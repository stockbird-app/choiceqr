require "spec_helper"

RSpec.describe ChoiceQR::Resources::Sections do
  let(:client) { build_client }
  let(:section_payload) { { "_id" => "1", "name" => "Drinks", "posID" => "10", "active" => true } }

  describe "#list" do
    it "GETs the list endpoint and returns an Array of Resource" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/sections/list")
             .to_return(status: 200, body: json([section_payload]), headers: api_headers)

      sections = client.sections.list
      expect(stub).to have_been_requested.once
      expect(sections).to all(be_a(ChoiceQR::Resource))
      expect(sections.first.name).to eq("Drinks")
      expect(sections.first.pos_id).to eq("10")
    end
  end

  describe "#get" do
    it "GETs a single section by id" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/sections/1")
             .to_return(status: 200, body: json(section_payload), headers: api_headers)

      section = client.sections.get("1")
      expect(stub).to have_been_requested.once
      expect(section.name).to eq("Drinks")
    end
  end

  describe "#create" do
    it "POSTs a camelCase body and returns the created Resource" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/sections")
             .with(body: hash_including("name" => "Drinks", "posID" => "10"))
             .to_return(status: 201, body: json(section_payload), headers: api_headers)

      section = client.sections.create(name: "Drinks", pos_id: "10")
      expect(stub).to have_been_requested.once
      expect(section.name).to eq("Drinks")
    end
  end

  describe "#update" do
    it "PUTs a camelCase body and returns true" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/sections/1")
             .with(body: hash_including("name" => "Beverages"))
             .to_return(status: 204, body: "", headers: {})

      expect(client.sections.update("1", name: "Beverages")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#set_position" do
    it "POSTs the raw array of ids to the bulk endpoint" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/sections/position/bulk")
             .with(body: %w[a b c])
             .to_return(status: 204, body: "", headers: {})

      expect(client.sections.set_position(%w[a b c])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs the section and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/menu/en/sections/1").to_return(status: 204, body: "", headers: {})

      expect(client.sections.delete("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
