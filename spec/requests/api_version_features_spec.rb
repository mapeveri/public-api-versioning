require 'rails_helper'

RSpec.describe "ApiVersion Features", type: :request do
  before(:all) do
    module TestVersions
      class Version20250201 < ApiVersion::Version
        timestamp "2025-02-01"
        resource :users

        payload do |p|
          p.add_field :nickname, default: "Anonymous"
          p.add_field :full_name do |item|
            "#{item[:first_name]} #{item[:last_name]}"
          end
          p.change_to_mandatory :email, default: "default@example.com"
        end

        endpoint_deprecated :users, :index
      end

      class Version20250301 < ApiVersion::Version
        timestamp "2025-03-01"
        resource :users

        endpoint_removed :users, :show
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestVersions)
  end

  before do
    allow(Rails.application.config.x).to receive(:version_files).and_return({
      "2025-02-01" => ["TestVersions::Version20250201"],
      "2025-03-01" => ["TestVersions::Version20250301"]
    })
  end

  describe "Payload Transformations (Version 2025-02-01)" do
    let(:headers) { { "X-API-VERSION" => "2025-02-01", "Content-Type" => "application/json" } }

    it "adds a field with a default value" do
      post "/api/v1/users", params: { user: { first_name: "John", last_name: "Doe" } }.to_json, headers: headers
      expect(response).to have_http_status(:created).or have_http_status(:ok)
    end
  end

  describe "Endpoint Deprecation (Version 2025-02-01)" do
    let(:headers) { { "X-API-VERSION" => "2025-02-01" } }

    it "adds a Warning header" do
      get "/api/v1/users", headers: headers
      expect(response.headers["Warning"]).to include("299 - Endpoint Deprecated")
    end
  end

  describe "Endpoint Removal (Version 2025-03-01)" do
    let(:headers) { { "X-API-VERSION" => "2025-03-01" } }

    it "returns 410 Gone" do
      get "/api/v1/users/1", headers: headers
      expect(response).to have_http_status(:gone)
      expect(JSON.parse(response.body)["error"]).to eq("Gone")
    end
  end
end
