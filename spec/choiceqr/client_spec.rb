require "spec_helper"

RSpec.describe ChoiceQR::Client do
  subject(:client) { build_client }

  describe "initialization" do
    it "defaults default_language to en" do
      expect(client.default_language).to eq("en")
    end

    it "accepts an explicit default_language" do
      expect(build_client(default_language: "de").default_language).to eq("de")
    end

    it "accepts optional timeout arguments" do
      expect(build_client(timeout: 60, open_timeout: 10)).to be_a(described_class)
    end
  end

  describe "resource accessors" do
    %i[
      place section_info sections categories dishes dish_options dish_labels
      pack cutlery full_menu areas location_points orders bookings feedbacks
    ].each do |method_name|
      it "responds to ##{method_name} and memoizes the resource wrapper" do
        collection = client.public_send(method_name)
        expect(collection).to be_a(ChoiceQR::Resources::Base)
        expect(client.public_send(method_name)).to be(collection)
      end
    end
  end

  describe ".exchange_token" do
    let(:token_url) { "#{API_BASE}/auth/connect/token" }

    it "posts the code/clientId/secret and returns a Resource" do
      stub = stub_request(:post, token_url)
             .with(body: hash_including("code" => "abc", "clientId" => "cid", "secret" => "sec"))
             .to_return(
               status: 200,
               body: json(varSymbol: "00000", domain: "example.choiceqr.com", token: "XXXXXXX"),
               headers: api_headers
             )

      result = described_class.exchange_token(code: "abc", client_id: "cid", secret: "sec")
      expect(stub).to have_been_requested.once
      expect(result).to be_a(ChoiceQR::Resource)
      expect(result.token).to eq("XXXXXXX")
      expect(result.var_symbol).to eq("00000")
    end

    it "raises AuthenticationError when the exchange fails" do
      stub_request(:post, token_url).to_return(status: 400, body: json(message: "Invalid code"), headers: api_headers)

      expect { described_class.exchange_token(code: "bad", client_id: "cid", secret: "sec") }
        .to raise_error(ChoiceQR::AuthenticationError)
    end
  end

  describe "#request" do
    let(:endpoint) { "#{API_BASE}/place" }

    it "sends the Bearer token in the Authorization header" do
      stub = stub_request(:get, endpoint)
             .with(headers: { "Authorization" => "Bearer #{TOKEN}" })
             .to_return(status: 200, body: json(name: "Test"), headers: api_headers)

      client.request(:get, "place")
      expect(stub).to have_been_requested.once
    end

    it "sends an x-idempotence-key header" do
      stub = stub_request(:get, endpoint)
             .with(headers: { "x-idempotence-key" => /.+/ })
             .to_return(status: 200, body: json(name: "Test"), headers: api_headers)

      client.request(:get, "place")
      expect(stub).to have_been_requested.once
    end

    it "sends a User-Agent header" do
      stub = stub_request(:get, endpoint)
             .with(headers: { "User-Agent" => %r{choiceqr-ruby/} })
             .to_return(status: 200, body: json(name: "Test"), headers: api_headers)

      client.request(:get, "place")
      expect(stub).to have_been_requested.once
    end

    it "raises ValidationError on 400" do
      stub_request(:get, endpoint).to_return(status: 400, body: json(name: "ValidationError", message: "Bad"),
                                             headers: api_headers)

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::ValidationError) do |error|
        expect(error.error_name).to eq("ValidationError")
      end
    end

    it "raises AuthenticationError on 401" do
      stub_request(:get, endpoint).to_return(status: 401, body: "", headers: api_headers)

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::AuthenticationError)
    end

    it "raises ForbiddenError on 403" do
      stub_request(:get, endpoint).to_return(status: 403, body: "", headers: api_headers)

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::ForbiddenError)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, endpoint).to_return(status: 404, body: "", headers: api_headers)

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::NotFoundError)
    end

    it "raises ServerError on 500 after exhausting retries" do
      stub_request(:get, endpoint).to_return(status: 500, body: json(message: "Boom"), headers: api_headers)

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::ServerError)
    end

    it "raises ConnectionError on network failure" do
      stub_request(:get, endpoint).to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::ConnectionError)
    end

    it "retries on 429 and succeeds if a later attempt is under the limit" do
      stub_request(:get, endpoint)
        .to_return({ status: 429, body: "", headers: api_headers },
                   { status: 200, body: json(name: "Test"), headers: api_headers })

      result = client.request(:get, "place")
      expect(result[:body]).to eq({ "name" => "Test" })
    end

    it "raises RateLimitError on persistent 429" do
      stub_request(:get, endpoint).to_return(status: 429, body: "", headers: api_headers)

      expect { client.request(:get, "place") }.to raise_error(ChoiceQR::RateLimitError)
    end

    it "returns a nil body for a 204 response" do
      stub_request(:delete, endpoint).to_return(status: 204, body: "", headers: {})

      result = client.request(:delete, "place")
      expect(result[:body]).to be_nil
    end
  end
end
