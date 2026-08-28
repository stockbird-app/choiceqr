require "spec_helper"

RSpec.describe ChoiceQR::WebhookEvent do
  describe ".parse" do
    it "parses a raw JSON string" do
      raw = json(id: "evt1", type: "dish.created", langCode: "en", varSymbol: "00000",
                 data: { "_id" => "d1", "name" => "Cappuccino" })

      event = described_class.parse(raw)
      expect(event.id).to eq("evt1")
      expect(event.type).to eq("dish.created")
      expect(event.lang_code).to eq("en")
      expect(event.var_symbol).to eq("00000")
    end

    it "accepts an already-parsed Hash" do
      event = described_class.parse("id" => "evt1", "type" => "place.changed")
      expect(event.id).to eq("evt1")
    end
  end

  describe "#data" do
    it "wraps an entity-shaped payload (e.g. dish.created) as a Resource" do
      event = described_class.parse(type: "dish.created", data: { "_id" => "d1", "name" => "Cappuccino" })

      expect(event.data).to be_a(ChoiceQR::Resource)
      expect(event.data.id).to eq("d1")
      expect(event.data.name).to eq("Cappuccino")
    end

    it "wraps a *.positionChanged payload's ids array with dot access" do
      event = described_class.parse(type: "section.positionChanged", data: { items: %w[s1 s2] })

      expect(event.data.items).to eq(%w[s1 s2])
    end

    it "wraps a *.removed payload's bare id" do
      event = described_class.parse(type: "dish.removed", data: { "_id" => "d1" })

      expect(event.data.id).to eq("d1")
    end
  end

  describe "hash-style and dot access for any other envelope field" do
    it "reaches fields without a named reader via []" do
      event = described_class.parse(id: "evt1", type: "import.full.done", timestramp: "2026-01-01T00:00:00Z")

      expect(event[:timestramp]).to eq("2026-01-01T00:00:00Z")
    end

    it "reaches fields without a named reader via dot access" do
      event = described_class.parse(id: "evt1", type: "import.full.done", timestramp: "2026-01-01T00:00:00Z")

      expect(event.timestramp).to eq("2026-01-01T00:00:00Z")
    end

    it "responds_to? a field it can reach via delegation" do
      event = described_class.parse(id: "evt1", type: "place.changed")

      expect(event.respond_to?(:type)).to be true
      expect(event.respond_to?(:nonexistent)).to be false
    end
  end

  describe "#to_h" do
    it "returns the full envelope as a plain hash" do
      event = described_class.parse(id: "evt1", type: "place.changed", varSymbol: "00000")

      expect(event.to_h).to eq(id: "evt1", type: "place.changed", var_symbol: "00000")
    end
  end

  describe "#inspect" do
    it "includes the type and id, not the full payload" do
      event = described_class.parse(id: "evt1", type: "dish.created", data: { "_id" => "d1" })

      expect(event.inspect).to eq('#<ChoiceQR::WebhookEvent type="dish.created" id="evt1">')
    end
  end

  describe "TYPES" do
    it "lists every documented event type" do
      expect(described_class::TYPES).to include("dish.created", "order.qrPayment.completed", "import.full.done")
    end
  end
end
