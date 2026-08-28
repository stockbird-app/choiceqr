require "spec_helper"

RSpec.describe ChoiceQR::KeyTransformer do
  describe ".snake_key" do
    it "converts camelCase to snake_case" do
      expect(described_class.snake_key("defaultLanguage")).to eq(:default_language)
    end

    it "converts posID to pos_id" do
      expect(described_class.snake_key("posID")).to eq(:pos_id)
    end

    it "strips a leading underscore" do
      expect(described_class.snake_key("_id")).to eq(:id)
    end

    it "accepts a symbol" do
      expect(described_class.snake_key(:alreadySnakeIsh)).to eq(:already_snake_ish)
    end
  end

  describe ".camel_key" do
    it "converts snake_case to lowerCamelCase" do
      expect(described_class.camel_key(:default_language)).to eq("defaultLanguage")
    end

    it "converts pos_id to posID" do
      expect(described_class.camel_key(:pos_id)).to eq("posID")
    end

    it "converts a pos_id suffix on a compound key to a PosID suffix" do
      expect(described_class.camel_key(:section_pos_id)).to eq("sectionPosID")
      expect(described_class.camel_key(:category_pos_id)).to eq("categoryPosID")
    end

    it "preserves a leading underscore" do
      expect(described_class.camel_key(:_id)).to eq("_id")
    end

    it "leaves a single-segment key unchanged" do
      expect(described_class.camel_key(:name)).to eq("name")
    end

    it "leaves an all-caps single-segment key unchanged (e.g. a marketplace code)" do
      expect(described_class.camel_key(:WOLT)).to eq("WOLT")
    end

    it "does not raise on an all-underscore key" do
      expect(described_class.camel_key(:_)).to eq("_")
      expect(described_class.camel_key(:"")).to eq("")
    end
  end

  describe ".to_snake" do
    it "recursively converts keys at every depth" do
      input = { "posID" => "5", "menuOptions" => [{ "defaultIndex" => 1 }] }
      expect(described_class.to_snake(input)).to eq(pos_id: "5", menu_options: [{ default_index: 1 }])
    end

    it "passes non-Hash/Array values through unchanged" do
      expect(described_class.to_snake("plain")).to eq("plain")
      expect(described_class.to_snake(nil)).to be_nil
    end
  end

  describe ".to_camel" do
    it "recursively converts keys at every depth" do
      input = { pos_id: "5", categories: [{ _id: "abc" }] }
      expect(described_class.to_camel(input)).to eq("posID" => "5", "categories" => [{ "_id" => "abc" }])
    end

    it "leaves marketplace-code keys inside nested data untouched" do
      input = { pos_id: "1", data: { WOLT: { price: 1000 }, GLOVO: { name: "x" } } }
      expect(described_class.to_camel(input)).to eq(
        "posID" => "1",
        "data" => { "WOLT" => { "price" => 1000 }, "GLOVO" => { "name" => "x" } }
      )
    end
  end
end
