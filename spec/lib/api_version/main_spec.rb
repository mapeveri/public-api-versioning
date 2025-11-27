require 'rails_helper'

RSpec.describe ApiVersion do
  describe ".from_request" do
    let(:version_files) do
      {
        "v1" => { "2025-03-01" => ["SomeVersionClass"] },
        "v2" => { "2025-11-01" => ["AnotherVersionClass"] }
      }
    end
    let(:api_current_versions) { { "v1" => "2025-03-01", "v2" => "2025-11-01" } }

    before do
      allow(Rails.application.config.x).to receive(:version_files).and_return(version_files)
      allow(Rails.application.config.x).to receive(:api_current_versions).and_return(api_current_versions)
      allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions, anything).and_return(true)
      allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions).and_return(true)
    end

    it "returns version files for the requested version in v1" do
      request = double("Request", headers: { "X-API-Version" => "2025-03-01" }, path: "/api/v1/users")
      controller = double("Controller", request: request)

      version_class = double("VersionClass")
      stub_const("SomeVersionClass", version_class)

      expect(described_class.from_request(request, controller)).to eq([version_class])
    end

    it "raises InvalidVersionError if version not found in namespace when using header" do
      request = double("Request", headers: { "X-API-Version" => "2025-11-01" }, path: "/api/v1/users")
      controller = double("Controller", request: request)

      expect { described_class.from_request(request, controller) }.to raise_error(ApiVersion::Errors::InvalidVersionError)
    end

    it "raises InvalidVersionError when X-API-Version header contains invalid version" do
      request = double("Request", headers: { "X-API-Version" => "9999-99-99" }, path: "/api/v1/users")
      controller = double("Controller", request: request)

      expect { described_class.from_request(request, controller) }.to raise_error(ApiVersion::Errors::InvalidVersionError)
    end

    it "does not raise error when no X-API-Version header is provided and uses current version" do
      request = double("Request", headers: {}, path: "/api/v1/users")
      controller = double("Controller", request: request)

      version_class = double("VersionClass")
      stub_const("SomeVersionClass", version_class)

      result = described_class.from_request(request, controller)
      expect(result).to eq([version_class])
    end
  end

  describe ".extract_api_namespace" do
    it "extracts v1 from path /api/v1/users" do
      controller = double("Controller", request: double(path: "/api/v1/users"))
      expect(described_class.send(:extract_api_namespace, controller, ["v1", "v2"])).to eq("v1")
    end

    it "extracts v2 from path /api/v2/products" do
      controller = double("Controller", request: double(path: "/api/v2/products"))
      expect(described_class.send(:extract_api_namespace, controller, ["v1", "v2"])).to eq("v2")
    end

    it "returns nil if version not in path" do
      controller = double("Controller", request: double(path: "/api/v3/users"))
      expect(described_class.send(:extract_api_namespace, controller, ["v1", "v2"])).to be_nil
    end
  end

  describe ".current_version" do
    context "with multi-API configuration" do
      let(:multi_versions) { { "v1" => "2025-03-01", "v2" => "2025-11-01" } }

      before do
        allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions, anything).and_return(true)
        allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions).and_return(true)
        allow(Rails.application.config.x).to receive(:api_current_versions).and_return(multi_versions)
      end

      it "returns v1 version for V1 path" do
        controller = double("Controller", request: double(path: "/api/v1/users"))
        expect(described_class.send(:current_version, controller)).to eq("2025-03-01")
      end

      it "returns v2 version for V2 path" do
        controller = double("Controller", request: double(path: "/api/v2/products"))
        expect(described_class.send(:current_version, controller)).to eq("2025-11-01")
      end

      it "raises error if version not found in path" do
        controller = double("Controller", request: double(path: "/api/v3/users"))
        expect { described_class.send(:current_version, controller) }.to raise_error(ApiVersion::Errors::MissingCurrentVersionError)
      end

      it "raises error if no controller provided" do
        expect { described_class.send(:current_version) }.to raise_error(ApiVersion::Errors::MissingCurrentVersionError)
      end
    end

    context "without multi-API configuration" do
      before do
        allow(Rails.application.config.x).to receive(:respond_to?).with(:api_current_versions).and_return(false)
      end

      it "raises error" do
        expect { described_class.send(:current_version) }.to raise_error(ApiVersion::Errors::MissingCurrentVersionError)
      end
    end
  end
end
