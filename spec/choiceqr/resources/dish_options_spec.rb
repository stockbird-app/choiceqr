require "spec_helper"

RSpec.describe ChoiceQR::Resources::DishOptions do
  let(:client) { build_client }
  let(:option_payload) { { "_id" => "opt1", "name" => "Size", "type" => "single", "section" => "sec1" } }

  describe "#list" do
    it "GETs options scoped to a section" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/options/list/sec1")
             .to_return(status: 200, body: json([option_payload]), headers: api_headers)

      options = client.dish_options.list("sec1")
      expect(stub).to have_been_requested.once
      expect(options.first.name).to eq("Size")
    end
  end

  describe "#create" do
    it "POSTs the option payload" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/options")
             .with(body: hash_including("name" => "Size", "type" => "single", "section" => "sec1"))
             .to_return(status: 201, body: json(option_payload), headers: api_headers)

      client.dish_options.create(name: "Size", type: "single", section: "sec1")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update" do
    it "PUTs and returns true" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/options/opt1").to_return(status: 204, body: "", headers: {})

      expect(client.dish_options.update("opt1", name: "Sizes")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#set_position" do
    it "POSTs the ordered ids scoped to the section" do
      stub = stub_request(:post, "#{API_BASE}/menu/en/options/sec1/position/bulk")
             .with(body: %w[a b])
             .to_return(status: 204, body: "", headers: {})

      expect(client.dish_options.set_position("sec1", %w[a b])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete" do
    it "DELETEs and returns true" do
      stub = stub_request(:delete, "#{API_BASE}/menu/en/options/opt1").to_return(status: 204, body: "", headers: {})

      expect(client.dish_options.delete("opt1")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#attach" do
    it "PUTs the dish id to attach" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/options/opt1/attach")
             .with(body: { "dish" => "dish1" })
             .to_return(status: 204, body: "", headers: {})

      expect(client.dish_options.attach("opt1", "dish1")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#detach" do
    it "PUTs the dish id to detach" do
      stub = stub_request(:put, "#{API_BASE}/menu/en/options/opt1/detach")
             .with(body: { "dish" => "dish1" })
             .to_return(status: 204, body: "", headers: {})

      expect(client.dish_options.detach("opt1", "dish1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
