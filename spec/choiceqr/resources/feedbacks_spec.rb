require "spec_helper"

RSpec.describe ChoiceQR::Resources::Feedbacks do
  let(:client) { build_client }
  let(:feedback_payload) { { "_id" => "1", "type" => "ORDER", "rateServe" => 5, "rateDish" => 4 } }

  describe "#list" do
    it "GETs /feedbacks with the given filters" do
      stub = stub_request(:get, "#{API_BASE}/feedbacks")
             .with(query: { "type" => "ORDER", "limit" => "10" })
             .to_return(status: 200, body: json([feedback_payload]), headers: api_headers)

      feedbacks = client.feedbacks.list(type: "ORDER", limit: 10)
      expect(stub).to have_been_requested.once
      expect(feedbacks.first.rate_serve).to eq(5)
    end

    it "formats Date/Time :from and :to as ISO8601 strings, not Ruby's default #to_s" do
      from = Date.new(2026, 1, 1)
      to = Time.utc(2026, 1, 31, 23, 59, 59)
      stub = stub_request(:get, "#{API_BASE}/feedbacks")
             .with(query: { "from" => from.iso8601, "to" => to.iso8601(3) })
             .to_return(status: 200, body: json([]), headers: api_headers)

      client.feedbacks.list(from: from, to: to)
      expect(stub).to have_been_requested.once
    end
  end

  describe "#get" do
    it "GETs a single feedback by id" do
      stub = stub_request(:get, "#{API_BASE}/feedbacks/1")
             .to_return(status: 200, body: json(feedback_payload), headers: api_headers)

      expect(client.feedbacks.get("1").rate_dish).to eq(4)
      expect(stub).to have_been_requested.once
    end
  end

  describe "#create" do
    it "POSTs the feedback payload and returns the created Resource" do
      stub = stub_request(:post, "#{API_BASE}/feedbacks")
             .with(body: hash_including(
               "refId" => "order1",
               "feedback" => hash_including("type" => "ORDER", "rateServe" => 4)
             ))
             .to_return(status: 200, body: json(feedback_payload), headers: api_headers)

      feedback = client.feedbacks.create(
        ref_id: "order1",
        feedback: { type: "ORDER", rate_serve: 4, rate_dish: 5, language: "en" },
        customer: { name: "John Doe" }
      )
      expect(stub).to have_been_requested.once
      expect(feedback).to be_a(ChoiceQR::Resource)
    end
  end
end
