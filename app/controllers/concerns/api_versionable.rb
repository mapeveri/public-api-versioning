module ApiVersionable
  extend ActiveSupport::Concern

  included do
    after_action :apply_version_transform
  end

  private

  def apply_version_transform
    return unless response.content_type == "application/json"

    version = ApiVersion.from_request(request)
    body = JSON.parse(response.body, symbolize_names: true)

    transformed = case controller_name
    when "users"
      ApiTransformations::UserTransformations.transform(body, version)
    else
      body
    end

    response.body = transformed.to_json
  end
end
