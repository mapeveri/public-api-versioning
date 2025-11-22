require 'rails_helper'

RSpec.describe "ApiVersion Integration", type: :request do
  before(:all) do
    module ApiVersionTest
      class TestController < ActionController::API
        include ApiVersion::ApiVersionable

        def index
          render json: { message: "ok" }
        end

        def show
          render json: { message: "ok" }
        end

        def create
          render json: params.permit!.to_h
        end
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :ApiVersionTest)
  end

  before(:all) do
    module TestVersions
      class Version20250201 < ApiVersion::Version
        timestamp "2025-02-01"
        resource :test

        payload do |p|
          p.add_field :nickname, default: "Anonymous"
          p.add_field :full_name do |item|
            "#{item[:first_name]} #{item[:last_name]}"
          end
          p.change_to_mandatory :email, default: "default@example.com"
        end

        endpoint_deprecated :test, :index
      end

      class Version20250301 < ApiVersion::Version
        timestamp "2025-03-01"
        resource :test

        endpoint_removed :test, :show
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestVersions)
  end

  before do
    Rails.application.routes.draw do
      post "/api/v1/test", to: "api_version_test/test#create"
      get "/api/v1/test", to: "api_version_test/test#index"
      get "/api/v1/test/:id", to: "api_version_test/test#show"
    end

    allow(Rails.application.config.x).to receive(:version_files).and_return({
      "2025-02-01" => [ "TestVersions::Version20250201" ],
      "2025-03-01" => [ "TestVersions::Version20250301" ]
    })
  end

  after do
    Rails.application.reload_routes!
  end

  describe "api_versionable" do
    describe "Payload Transformations (Version 2025-02-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-02-01", "Content-Type" => "application/json" } }

      it "adds a field with a default value" do
        post "/api/v1/test", params: { test: { first_name: "John", last_name: "Doe" } }.to_json, headers: headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response[:test][:nickname]).to eq("Anonymous")
        expect(json_response[:test][:full_name]).to eq("John Doe")
        expect(json_response[:test][:email]).to eq("default@example.com")
      end
    end

    describe "Endpoint Deprecation (Version 2025-02-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-02-01" } }

      it "adds a Warning header" do
        get "/api/v1/test", headers: headers
        expect(response.headers["Warning"]).to include("299 - Endpoint Deprecated")
      end
    end

    describe "Endpoint Removal (Version 2025-03-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-03-01" } }

      it "returns 410 Gone" do
        get "/api/v1/test/1", headers: headers
        expect(response).to have_http_status(:gone)
        expect(JSON.parse(response.body)["error"]).to eq("Gone")
      end
    end
  end
end
