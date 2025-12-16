# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhoneParserService do
  describe "#initialize" do
    it "parses the raw phone with Phonelib and stores it as #phone" do
      phone_double = instance_double("Phonelib::Phone")

      expect(Phonelib).to receive(:parse).with("+48500600700").and_return(phone_double)

      service = described_class.new("+48500600700")
      expect(service.phone).to eq(phone_double)
    end
  end

  describe "#valid?" do
    it "delegates to the parsed phone object" do
      phone_double = instance_double("Phonelib::Phone", valid?: true)
      allow(Phonelib).to receive(:parse).and_return(phone_double)

      expect(described_class.new("anything")).to be_valid
    end
  end

  context "when phone is valid" do
    subject(:service) { described_class.new("+48500600700") }

    let(:phone_double) do
      instance_double(
        "Phonelib::Phone",
        valid?: true,
        country_code: "48",
        national_number: "500600700",
        e164: "+48500600700"
      )
    end

    before do
      allow(Phonelib).to receive(:parse).with("+48500600700").and_return(phone_double)
    end

    describe "#country_code" do
      it "returns country code with leading '+'" do
        expect(service.country_code).to eq("+48")
      end
    end

    describe "#national_number" do
      it "returns national number" do
        expect(service.national_number).to eq("500600700")
      end
    end

    describe "#e164" do
      it "returns the E.164 formatted number" do
        expect(service.e164).to eq("+48500600700")
      end
    end

    describe "#to_h" do
      it "returns a hash with country_code, national_number and e164" do
        expect(service.to_h).to eq(
          country_code: "+48",
          national_number: "500600700",
          e164: "+48500600700"
        )
      end
    end
  end

  context "when phone is invalid" do
    subject(:service) { described_class.new("not-a-phone") }

    let(:phone_double) do
      instance_double(
        "Phonelib::Phone",
        valid?: false,
        country_code: nil,
        national_number: nil,
        e164: nil
      )
    end

    before do
      allow(Phonelib).to receive(:parse).with("not-a-phone").and_return(phone_double)
    end

    describe "#country_code" do
      it "returns nil" do
        expect(service.country_code).to be_nil
      end
    end

    describe "#national_number" do
      it "returns nil" do
        expect(service.national_number).to be_nil
      end
    end

    describe "#e164" do
      it "returns nil" do
        expect(service.e164).to be_nil
      end
    end

    describe "#to_h" do
      it "returns an empty hash" do
        expect(service.to_h).to eq({})
      end
    end
  end
end
