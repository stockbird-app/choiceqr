require "spec_helper"

RSpec.describe ChoiceQR::Resources::FullMenu do
  let(:client) { build_client }

  describe "#list" do
    it "GETs the full client menu" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/full/list")
             .to_return(status: 200, body: json(sections: [], categories: [], menu: []), headers: api_headers)

      menu = client.full_menu.list
      expect(stub).to have_been_requested.once
      expect(menu.sections).to eq([])
    end
  end

  describe "#import" do
    it "POSTs the payload with preserveMissingItems as a query param" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/full")
             .with(query: { "preserveMissingItems" => "true" },
                   body: hash_including("sections" => [{ "posID" => "1", "name" => "Main" }]))
             .to_return(status: 204, body: "", headers: {})

      result = client.full_menu.import(sections: [{ pos_id: "1", name: "Main" }], preserve_missing_items: true)
      expect(result).to be true
      expect(stub).to have_been_requested.once
    end

    it "converts cross-reference posID suffixes (sectionPosID, categoryPosID)" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/full")
             .with(body: hash_including(
               "categories" => [{ "posID" => "cat1", "sectionPosID" => "sec1", "name" => "Hot" }],
               "dishes" => [{ "posID" => "d1", "categoryPosID" => "cat1", "name" => "Coffee", "price" => 300 }]
             ))
             .to_return(status: 204, body: "", headers: {})

      client.full_menu.import(
        categories: [{ pos_id: "cat1", section_pos_id: "sec1", name: "Hot" }],
        dishes: [{ pos_id: "d1", category_pos_id: "cat1", name: "Coffee", price: 300 }]
      )
      expect(stub).to have_been_requested.once
    end
  end

  describe "#patch_dishes" do
    it "PATCHes only the dishes payload" do
      stub = stub_request(:patch, "#{API_BASE}/menu/en/full/dishes")
             .with(body: hash_including("dishes" => [{ "posID" => "1", "price" => 500 }]))
             .to_return(status: 204, body: "", headers: {})

      expect(client.full_menu.patch_dishes(dishes: [{ pos_id: "1", price: 500 }])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#sync_availability" do
    it "POSTs the availability payload with skipMissing as a query param" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/full/availability")
             .with(query: { "skipMissing" => "true" },
                   body: hash_including("dishes" => [{ "posID" => "525", "active" => false }]))
             .to_return(status: 204, body: "", headers: {})

      result = client.full_menu.sync_availability(
        dishes: [{ pos_id: "525", active: false }], skip_missing: true
      )
      expect(result).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#sync_chain_availability" do
    it "POSTs the chain availability payload" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/full/chain/availability")
             .with(body: hash_including("sections" => [{ "posID" => "1" }]))
             .to_return(status: 204, body: "", headers: {})

      expect(client.full_menu.sync_chain_availability(sections: [{ pos_id: "1" }])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#sync_marketplace_data" do
    it "leaves marketplace codes untouched and returns the sync job id" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/full/marketplace/data")
             .with(body: {
                     "dishes" => [
                       { "posID" => "1", "data" => { "WOLT" => { "price" => 1000, "name" => "Wolt name" } } },
                     ],
                   })
             .to_return(status: 200, body: json(id: "sync1"), headers: api_headers)

      result = client.full_menu.sync_marketplace_data(
        dishes: [{ pos_id: "1", data: { WOLT: { price: 1000, name: "Wolt name" } } }]
      )
      expect(stub).to have_been_requested.once
      expect(result.id).to eq("sync1")
    end
  end

  describe "#marketplace_sync_status" do
    it "GETs the sync status" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/full/marketplace/data/status/sync1")
             .to_return(status: 200, body: json(done: true, progress: 100), headers: api_headers)

      status = client.full_menu.marketplace_sync_status("sync1")
      expect(stub).to have_been_requested.once
      expect(status.done).to be true
    end
  end
end
