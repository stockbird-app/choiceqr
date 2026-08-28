require "spec_helper"

RSpec.describe ChoiceQR::Resources::Place do
  let(:client) { build_client }

  describe "#get" do
    it "GETs /place and returns a Resource" do
      stub = stub_request(:get, "#{API_BASE}/place")
             .to_return(status: 200, body: json(name: "Test company", currency: "EUR"), headers: api_headers)

      place = client.place.get
      expect(stub).to have_been_requested.once
      expect(place).to be_a(ChoiceQR::Resource)
      expect(place.name).to eq("Test company")
      expect(place.currency).to eq("EUR")
    end
  end
end
