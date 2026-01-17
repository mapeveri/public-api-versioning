require 'rails_helper'

RSpec.describe ApiVersion do
  describe "Multiple Supported Versions" do
    let(:supported_versions) do
      {
        "v1" => ["2025-01-01", "2025-06-01", "2025-12-01"],
        "v2" => ["2026-01-01"]
      }
    end

    before do
      allow(ApiVersion.config).to receive(:api_supported_versions).and_return(supported_versions)
      allow(ApiVersion.config).to receive(:api_current_versions).and_return({})
    end

    describe ".current_version" do
      it "returns the latest version for v1" do
        controller = double("Controller", request: double(path: "/api/v1/users"))
        expect(ApiVersion.send(:current_version, controller)).to eq("2025-12-01")
      end

      it "returns the single version for v2" do
        controller = double("Controller", request: double(path: "/api/v2/users"))
        expect(ApiVersion.send(:current_version, controller)).to eq("2026-01-01")
      end
    end

    describe ".from_request" do
      let(:v1_june) { double("Version", namespace_value: "v1", timestamp_value: "2025-06-01") }
      let(:v1_dec) { double("Version", namespace_value: "v1", timestamp_value: "2025-12-01") }

      before do

        allow(ApiVersion::Version).to receive(:all_versions).and_return([v1_june, v1_dec])
        allow(ApiVersion).to receive(:load_versions)
      end

      it "selects available versions valid for the requested version" do
        request = double("Request", headers: { "X-API-Version" => "2025-08-01" }, path: "/api/v1/users")
        controller = double("Controller", request: request)

        # Logic in main: select v where v.timestamp_value >= requested_version
        # Wait, the main logic for available_versions is:
        # available_versions.select { |v| v.timestamp_value >= requested_version }
        # So if I request 2025-08-01:
        # v1_june (2025-06-01) >= 2025-08-01 -> False
        # v1_dec (2025-12-01) >= 2025-08-01 -> True
        # It returns [v1_dec] which represents changes *since* request?
        # Let's verify standard behavior.
        # Usually versions are applied if they are "newer than" the requested version (transformations to bring code back to old state? Or up?)
        # Base code is latest.
        # If I request old version, I need to apply transformations "down"?
        # Or if I request new version...
        
        # Let's look at main.rb line 25: v.timestamp_value >= requested_version
        # Yes.
        
        results = ApiVersion.from_request(request, controller)
        expect(results).to include(v1_dec)
        expect(results).not_to include(v1_june)
      end

      it "raises error if requested version is newer than latest supported" do
         request = double("Request", headers: { "X-API-Version" => "2026-01-01" }, path: "/api/v1/users")
         controller = double("Controller", request: request)
         
         # Latest is 2025-12-01
         expect { ApiVersion.from_request(request, controller) }.to raise_error(ApiVersion::Errors::InvalidVersionError)
      end
    end
    
    describe "Fallback to api_current_versions" do
      before do
        allow(ApiVersion.config).to receive(:api_supported_versions).and_return(nil)
        allow(ApiVersion.config).to receive(:api_current_versions).and_return({ "v1" => "2025-01-01" })
      end

      it "uses api_current_versions as single supported version" do
        controller = double("Controller", request: double(path: "/api/v1/users"))
        expect(ApiVersion.send(:current_version, controller)).to eq("2025-01-01")
      end
    end
  end
end
