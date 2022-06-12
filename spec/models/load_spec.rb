# frozen_string_literal: true

require "rails_helper"

RSpec.describe Load do
  context "[validations]" do
    it "verifies at least one weight is > 0" do
      expect(build(:load, name: "foo", weight: 0, bags_weight: 0)).not_to be_valid
      expect(build(:load, name: "foo", weight: 1, bags_weight: 0)).to be_valid
      expect(build(:load, name: "foo", weight: 0, bags_weight: 1)).to be_valid
      expect(build(:load, name: "foo", weight: 1, bags_weight: 1)).to be_valid
    end
  end

  describe "#slug" do
    it "sets it from the name" do
      expect(create(:load, :passenger, name: "Sancho Sample").slug).to eq("sancho-sample")
    end

    it "updates it from the name" do
      load = create(:load, :passenger)
      load.update! name: "Test User"
      expect(load.slug).to eq("test-user")
    end
  end

  describe "#passenger?" do
    it "returns true if weight > 0" do
      expect(build(:load, weight: 1)).to be_passenger
    end

    it "returns false if weight is 0" do
      expect(build(:load, weight: 0)).not_to be_passenger
    end
  end

  describe "#cargo?" do
    it "returns true if weight is 0 and bags_weight > 0" do
      expect(build(:load, weight: 0, bags_weight: 1)).to be_cargo
    end

    it "returns false if weight > 0" do
      expect(build(:load, weight: 1, bags_weight: 1)).not_to be_cargo
    end
  end
end
