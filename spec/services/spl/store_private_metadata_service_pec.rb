# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spl::StorePrivateMetadataService do
  let(:private_metadata) do
    {
      "spl_url" => "https://spl.test",
      "spl_api_user" => "user",
      "spl_api_token" => "token",
      "spl_partner_code" => "partner",
      "spl_place_code" => "place",
      "spl_update_status_mode" => "mode",
      "spl_prg_code" => "PRG",
      "spl_mode" => "mode",
      "spl_pos_key" => "poskey"
    }
  end

  let(:store) { instance_double(Spree::Store, private_metadata: private_metadata) }

  describe ".all" do
    context "when store is nil" do
      it "returns an empty hash" do
        expect(described_class.all(nil)).to eq({})
      end
    end

    context "when store.private_metadata is nil" do
      let(:store) { instance_double(Spree::Store, private_metadata: nil) }

      it "returns an empty hash" do
        expect(described_class.all(store)).to eq({})
      end
    end

    it "returns the private_metadata contents" do
      expect(described_class.all(store)).to eq(private_metadata)
    end

    it "returns a copy that does not allow mutation of the original store hash" do
      result = described_class.all(store)
      result["spl_url"] = "https://changed.test"

      expect(store.private_metadata["spl_url"]).to eq("https://spl.test")
    end

    it "deep-dups nested hashes (if present) so nested mutation does not affect the original" do
      nested = { "outer" => { "inner" => "value" } }
      store_with_nested = instance_double(Spree::Store, private_metadata: nested)

      result = described_class.all(store_with_nested)
      result["outer"]["inner"] = "changed"

      expect(store_with_nested.private_metadata["outer"]["inner"]).to eq("value")
    end
  end

  describe ".fetch" do
    context "when store is nil" do
      it "returns the default when provided" do
        expect(described_class.fetch(nil, :spl_url, default: "x")).to eq("x")
      end

      it "raises KeyError when key is missing and no default is provided" do
        expect(described_class.fetch(nil, :spl_url)).to be_nil
      end
    end

    it "fetches by symbol key" do
      expect(described_class.fetch(store, :spl_url)).to eq("https://spl.test")
    end

    it "fetches by string key" do
      expect(described_class.fetch(store, "spl_url")).to eq("https://spl.test")
    end

    it "returns default when key is missing" do
      expect(described_class.fetch(store, :missing_key, default: "fallback")).to eq("fallback")
    end

    it "raises KeyError when key is missing and no default is provided" do
      expect(described_class.fetch(store, :missing_key)).to be_nil
    end

    it "does not allow callers to mutate nested values through the returned hash" do
      nested = { "cfg" => { "token" => "abc" } }
      store_with_nested = instance_double(Spree::Store, private_metadata: nested)

      cfg = described_class.fetch(store_with_nested, :cfg)
      cfg["token"] = "changed"

      expect(store_with_nested.private_metadata["cfg"]["token"]).to eq("abc")
    end
  end
end
