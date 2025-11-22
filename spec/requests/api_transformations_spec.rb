require 'rails_helper'

RSpec.describe "ApiTransformations", type: :request do
  describe "Version 2025-01-01" do
    let(:headers) { { "X-API-VERSION" => "2025-01-01", "Content-Type" => "application/json" } }

    it "splits name into first_name and last_name on request and combines them on response" do
      post "/api/v1/users", params: { user: { name: "Luis Vives", email: "luis@example.com" } }.to_json, headers: headers

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      json_response = JSON.parse(response.body, symbolize_names: true)

      expect(json_response[:name]).to eq("Luis Vives")
      expect(json_response[:first_name]).to be_nil
      expect(json_response[:last_name]).to be_nil
    end
  end

  describe "Version 2025-11-01" do
    let(:headers) { { "X-API-VERSION" => "2025-11-01", "Content-Type" => "application/json" } }

    it "uses first_name and last_name directly" do
      post "/api/v1/users", params: { user: { first_name: "Luis", last_name: "Vives", email: "luis@example.com" } }.to_json, headers: headers

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      json_response = JSON.parse(response.body, symbolize_names: true)

      expect(json_response[:first_name]).to eq("Luis")
      expect(json_response[:last_name]).to eq("Vives")
      expect(json_response[:name]).to be_nil
    end
  end
end
