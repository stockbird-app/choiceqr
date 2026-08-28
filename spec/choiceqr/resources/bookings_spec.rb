require "spec_helper"

RSpec.describe ChoiceQR::Resources::Bookings do
  let(:client) { build_client }
  let(:booking_payload) { { "_id" => "1", "status" => "CREATED", "num" => 7 } }

  describe "#list" do
    it "GETs /bookings/list with camelCase query params" do
      stub = stub_request(:get, "#{API_BASE}/bookings/list")
             .with(query: { "periodField" => "bookingDt", "perPage" => "20" })
             .to_return(status: 200, body: json([booking_payload]), headers: api_headers)

      bookings = client.bookings.list(period_field: "bookingDt", per_page: 20)
      expect(stub).to have_been_requested.once
      expect(bookings.first.num).to eq(7)
    end
  end

  describe "#get" do
    it "GETs a single booking by id" do
      stub = stub_request(:get, "#{API_BASE}/bookings/1")
             .to_return(status: 200, body: json(booking_payload), headers: api_headers)

      expect(client.bookings.get("1").status).to eq("CREATED")
      expect(stub).to have_been_requested.once
    end
  end

  describe "#confirm" do
    it "PUTs the location points to confirm" do
      stub = stub_request(:put, "#{API_BASE}/bookings/1/confirm")
             .with(body: { "locationPoints" => ["point1"] })
             .to_return(status: 204, body: "", headers: {})

      expect(client.bookings.confirm("1", location_points: ["point1"])).to be true
      expect(stub).to have_been_requested.once
    end
  end

  describe "#cancel" do
    it "PUTs the cancel reason" do
      stub = stub_request(:put, "#{API_BASE}/bookings/1/cancel")
             .with(body: { "cancelReason" => "No longer available" })
             .to_return(status: 204, body: "", headers: {})

      expect(client.bookings.cancel("1", cancel_reason: "No longer available")).to be true
      expect(stub).to have_been_requested.once
    end
  end
end
