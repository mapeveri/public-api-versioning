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

  module TestVersions
    class Version20250201 < ApiVersion::Version
      timestamp "2025-02-01"
      resource :test
      namespace "v1"

      payload do |p|
        p.add_field :nickname, default: "Anonymous"
        p.add_field :full_name do |item|
          "#{item[:first_name]} #{item[:last_name]}"
        end
        p.change_to_mandatory :email, default: "default@example.com"
      end

      response do |r|
        r.add_field :status_message, default: "Operation successful"
      end

      endpoint_deprecated :test, :index
    end

    class Version20250301 < ApiVersion::Version
      timestamp "2025-03-01"
      resource :test
      namespace "v1"

      endpoint_removed :test, :show
    end

    class Version20250401 < ApiVersion::Version
      timestamp "2025-04-01"
      resource :test
      namespace "v1"

      payload do |p|
        p.remove_field :password
        p.rename_field :full_name, :name
      end
    end

    class Version20250501 < ApiVersion::Version
      timestamp "2025-05-01"
      resource :test
      namespace "v1"

      payload do |p|
        p.nest :user do |u|
          u.rename_field :full_name, :name
        end
        p.each :items do |i|
          i.add_field :active, default: true
        end
        p.move_field :legacy_id, to: [ :meta, :id ]
      end
    end

    class Version20250601 < ApiVersion::Version
      timestamp "2025-06-01"
      resource :test
      namespace "v1"

      response do |r|
        r.nest :nested_data do |n|
          n.rename_field :old_key, :new_key
        end
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

    allow(Rails.application.config.x).to receive(:api_current_versions).and_return({ "v1" => "2025-06-01" })
    allow(ApiVersion).to receive(:load_versions) # Use only versions defined in this spec
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
        expect(json_response[:test][:name]).to eq("John Doe")
        expect(json_response[:test][:email]).to eq("default@example.com")
      end
    end

    describe "Response Transformations (Version 2025-02-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-02-01" } }

      it "adds a field to the response" do
        get "/api/v1/test", headers: headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response[:status_message]).to eq("Operation successful")
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

    describe "Payload Transformations (Version 2025-04-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-04-01", "Content-Type" => "application/json" } }

      it "removes and renames fields" do
        post "/api/v1/test", params: { test: { password: "secret", full_name: "John Doe" } }.to_json, headers: headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response[:test]).not_to have_key(:password)
        expect(json_response[:test][:name]).to eq("John Doe")
        expect(json_response[:test]).not_to have_key(:full_name)
      end
    end

    describe "Advanced Transformations (Version 2025-05-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-05-01", "Content-Type" => "application/json" } }

      it "applies nest, each, and move transformations" do
        params = {
          test: {
            user: { full_name: "Jane Doe" },
            items: [ { name: "Item A" } ],
            legacy_id: 999
          }
        }
        post "/api/v1/test", params: params.to_json, headers: headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response[:test][:user][:name]).to eq("Jane Doe")
        expect(json_response[:test][:items].first[:active]).to be true
        expect(json_response[:test][:meta][:id]).to eq(999)
        expect(json_response[:test]).not_to have_key(:legacy_id)
      end
    end

    describe "Response Nest Transformation (Version 2025-06-01)" do
      let(:headers) { { "X-API-VERSION" => "2025-06-01" } }

      before do
        # Mock the controller response for this specific test
        allow_any_instance_of(ApiVersionTest::TestController).to receive(:index) do |controller|
          controller.render json: { nested_data: { old_key: "value" } }
        end
      end

      it "applies nest transformation to response" do
        get "/api/v1/test", headers: headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response[:nested_data][:new_key]).to eq("value")
        expect(json_response[:nested_data]).not_to have_key(:old_key)
      end
    end
  end
end
