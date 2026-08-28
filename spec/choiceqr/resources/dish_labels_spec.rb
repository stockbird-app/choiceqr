require "spec_helper"

RSpec.describe ChoiceQR::Resources::DishLabels do
  let(:client) { build_client }

  describe "#list" do
    it "GETs the dish labels list" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/dish-labels/list")
             .to_return(status: 200, body: json([{ "_id" => "1", "name" => "Chef's pick" }]), headers: api_headers)

      labels = client.dish_labels.list
      expect(stub).to have_been_requested.once
      expect(labels.first.name).to eq("Chef's pick")
    end

    it "accepts a language override" do
      stub = stub_request(:get, "#{API_BASE}/menu/de/dish-labels/list")
             .to_return(status: 200, body: json([]), headers: api_headers)

      client.dish_labels.list(language: "de")
      expect(stub).to have_been_requested.once
    end
  end
end
