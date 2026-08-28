require "spec_helper"

RSpec.describe ChoiceQR::Resource do
  subject(:resource) { described_class.new(attributes) }

  let(:attributes) do
    {
      "_id" => "1",
      "name" => "Cappuccino",
      "posID" => "5",
      "menuOptions" => [
        { "_id" => "opt1", "name" => "Size", "list" => [{ "_id" => "s", "price" => 0 }] },
      ],
      "pack" => nil,
    }
  end

  it "exposes snake_case attributes via dot notation" do
    expect(resource.id).to eq("1")
    expect(resource.name).to eq("Cappuccino")
    expect(resource.pos_id).to eq("5")
  end

  it "exposes attributes via hash-style access with symbol or string keys" do
    expect(resource[:name]).to eq("Cappuccino")
    expect(resource["posID"]).to eq("5")
  end

  it "wraps nested hashes as Resource instances, at any depth" do
    option = resource.menu_options.first
    expect(option).to be_a(described_class)
    expect(option.name).to eq("Size")
    expect(option.list.first).to be_a(described_class)
    expect(option.list.first.price).to eq(0)
  end

  it "leaves nil values as nil rather than wrapping them" do
    expect(resource.pack).to be_nil
  end

  it "raises NoMethodError for unknown attributes" do
    expect { resource.nonexistent }.to raise_error(NoMethodError)
  end

  it "responds_to? known attributes but not unknown ones" do
    expect(resource.respond_to?(:name)).to be true
    expect(resource.respond_to?(:nonexistent)).to be false
  end

  describe "#to_h" do
    it "returns a plain snake_case-keyed hash with nested Resources unwrapped" do
      hash = resource.to_h
      expect(hash[:menu_options].first).to be_a(Hash)
      expect(hash[:menu_options].first[:list].first).to eq(id: "s", price: 0)
    end

    it "returns a deep copy that mutation does not affect the original" do
      hash = resource.to_h
      hash[:menu_options] << :mutated
      expect(resource.menu_options.size).to eq(1)
    end
  end

  describe "#==" do
    it "compares by attribute contents" do
      other = described_class.new(attributes)
      expect(resource).to eq(other)
    end

    it "is not equal to a plain Hash" do
      expect(resource).not_to eq(attributes)
    end
  end

  describe "#inspect" do
    it "includes the class name and attributes" do
      expect(resource.inspect).to include("ChoiceQR::Resource", "Cappuccino")
    end
  end
end
