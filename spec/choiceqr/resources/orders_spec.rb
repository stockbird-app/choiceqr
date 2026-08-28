require "spec_helper"

RSpec.describe ChoiceQR::Resources::Orders do
  let(:client) { build_client }
  let(:order_payload) { { "_id" => "1", "num" => 42, "type" => "takeaway", "guid" => "guid1" } }

  describe "#list" do
    it "GETs /orders/list with camelCase query params" do
      stub = stub_request(:get, "#{API_BASE}/orders/list")
             .with(query: { "includeApproved" => "true", "perPage" => "10" })
             .to_return(status: 200, body: json([order_payload]), headers: api_headers)

      orders = client.orders.list(include_approved: true, per_page: 10)
      expect(stub).to have_been_requested.once
      expect(orders.first.num).to eq(42)
    end

    it "formats a Time :since as an ISO8601 string" do
      since = Time.utc(2021, 6, 22, 16, 51, 4)
      stub = stub_request(:get, "#{API_BASE}/orders/list")
             .with(query: { "since" => since.iso8601(3) })
             .to_return(status: 200, body: json([]), headers: api_headers)

      client.orders.list(since: since)
      expect(stub).to have_been_requested.once
    end

    it "formats a Date :since as an ISO8601 date string, without raising" do
      since = Date.new(2021, 6, 22)
      stub = stub_request(:get, "#{API_BASE}/orders/list")
             .with(query: { "since" => since.iso8601 })
             .to_return(status: 200, body: json([]), headers: api_headers)

      client.orders.list(since: since)
      expect(stub).to have_been_requested.once
    end

    it "joins an Array of branch ids with commas" do
      stub = stub_request(:get, "#{API_BASE}/orders/list")
             .with(query: { "branches" => "b1,b2" })
             .to_return(status: 200, body: json([]), headers: api_headers)

      client.orders.list(branches: %w[b1 b2])
      expect(stub).to have_been_requested.once
    end
  end

  describe "#list_archive" do
    it "GETs /orders/list/archive with required from/till params" do
      from = Time.utc(2021, 1, 1)
      till = Time.utc(2021, 2, 1)
      stub = stub_request(:get, "#{API_BASE}/orders/list/archive")
             .with(query: { "from" => from.iso8601(3), "till" => till.iso8601(3) })
             .to_return(status: 200, body: json([order_payload]), headers: api_headers)

      orders = client.orders.list_archive(from: from, till: till)
      expect(stub).to have_been_requested.once
      expect(orders.size).to eq(1)
    end
  end

  describe "#get" do
    it "GETs a single order by id" do
      stub = stub_request(:get, "#{API_BASE}/orders/1")
             .to_return(status: 200, body: json(order_payload), headers: api_headers)

      expect(client.orders.get("1").num).to eq(42)
      expect(stub).to have_been_requested.once
    end
  end

  describe "#get_by_guid" do
    it "GETs a single order by guid" do
      stub = stub_request(:get, "#{API_BASE}/orders/guid/guid1")
             .to_return(status: 200, body: json(order_payload), headers: api_headers)

      expect(client.orders.get_by_guid("guid1").guid).to eq("guid1")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#update_delivery" do
    it "PUTs the delivery status update" do
      stub = stub_request(:put, "#{API_BASE}/orders/1/delivery")
             .with(body: hash_including("deliveryStatus" => "processing"))
             .to_return(status: 204, body: "", headers: {})

      expect(client.orders.update_delivery("1", delivery_status: "processing")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#cancel" do
    it "PUTs the cancel reason" do
      stub = stub_request(:put, "#{API_BASE}/orders/1/cancel")
             .with(body: { "reason" => "Out of stock" })
             .to_return(status: 204, body: "", headers: {})

      expect(client.orders.cancel("1", reason: "Out of stock")).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#close" do
    it "PUTs with no body and returns true" do
      stub = stub_request(:put, "#{API_BASE}/orders/1/close").to_return(status: 204, body: "", headers: {})

      expect(client.orders.close("1")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
