require "spec_helper"

RSpec.describe ChoiceQR::Resources::SectionInfo do
  let(:client) { build_client }

  describe "#get" do
    it "GETs /menu/:language/section-info/:sectionId using the client's default_language" do
      stub = stub_request(:get, "#{API_BASE}/menu/en/section-info/sec1")
             .to_return(status: 200, body: json(_id: "info1", value: "Welcome!", section: "sec1"),
                        headers: api_headers)

      info = client.section_info.get("sec1")
      expect(stub).to have_been_requested.once
      expect(info.value).to eq("Welcome!")
    end

    it "accepts a language override" do
      stub = stub_request(:get, "#{API_BASE}/menu/de/section-info/sec1")
             .to_return(status: 200, body: json(_id: "info1", value: "Willkommen!"), headers: api_headers)

      client.section_info.get("sec1", language: "de")
      expect(stub).to have_been_requested.once
    end
  end
end
