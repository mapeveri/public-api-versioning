require 'rails_helper'

RSpec.describe ApiVersion do
  describe ".extract_api_namespace" do
    it "extracts v1 from Api::V1::UsersController" do
      controller = double("Controller", class: double(name: "Api::V1::UsersController"))
      expect(described_class.send(:extract_api_namespace, controller)).to eq("v1")
    end

    it "extracts v2 from Api::V2::ProductsController" do
      controller = double("Controller", class: double(name: "Api::V2::ProductsController"))
      expect(described_class.send(:extract_api_namespace, controller)).to eq("v2")
    end

    it "returns nil for non-API controller" do
      controller = double("Controller", class: double(name: "UsersController"))
      expect(described_class.send(:extract_api_namespace, controller)).to be_nil
    end
  end

  describe ".current_version" do
    context "with single API configuration (backward compatible)" do
      before do
        allow(Rails.application.config.x).to receive(:api_current_version).and_return("2025-11-01")
        allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions).and_return(false)
      end

      it "returns the configured version" do
        expect(described_class.send(:current_version)).to eq("2025-11-01")
      end

      it "returns the configured version even with controller" do
        controller = double("Controller", class: double(name: "Api::V1::UsersController"))
        expect(described_class.send(:current_version, controller)).to eq("2025-11-01")
      end
    end

    context "with multi-API configuration" do
      let(:multi_versions) { { "v1" => "2025-03-01", "v2" => "2025-11-01" } }

      before do
        allow(Rails.application.config.x).to receive(:respond_to?).and_call_original
        allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions).and_return(true)
        allow(Rails.application.config.x).to receive(:api_current_versions).and_return(multi_versions)
        allow(Rails.application.config.x).to receive(:api_current_version).and_return("2025-11-01")
      end

      it "returns v1 version for V1 controller" do
        controller = double("Controller", class: double(name: "Api::V1::UsersController"))
        expect(described_class.send(:current_version, controller)).to eq("2025-03-01")
      end

      it "returns v2 version for V2 controller" do
        controller = double("Controller", class: double(name: "Api::V2::ProductsController"))
        expect(described_class.send(:current_version, controller)).to eq("2025-11-01")
      end

      it "falls back to single config if namespace not found" do
        controller = double("Controller", class: double(name: "Api::V3::UsersController"))
        expect(described_class.send(:current_version, controller)).to eq("2025-11-01")
      end

      it "falls back to single config if no controller provided" do
        expect(described_class.send(:current_version)).to eq("2025-11-01")
      end
    end
  end
end
