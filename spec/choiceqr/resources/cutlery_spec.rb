require "spec_helper"

RSpec.describe ChoiceQR::Resources::Cutlery do
  let(:client) { build_client }

  describe "#get" do
    it "GETs the cutlery configuration" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/cutlery")
             .to_return(status: 200, body: json(show: true, showPersonNumber: false), headers: api_headers)

      cutlery = client.cutlery.get
      expect(stub).to have_been_requested.once
      expect(cutlery.show).to be true
      expect(cutlery.show_person_number).to be false
    end
  end

  describe "#update" do
    it "PUTs a camelCase body and returns true" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/cutlery")
             .with(body: hash_including("show" => true, "requiredCutlery" => true))
             .to_return(status: 204, body: "", headers: {})

      expect(client.cutlery.update(show: true, required_cutlery: true)).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
