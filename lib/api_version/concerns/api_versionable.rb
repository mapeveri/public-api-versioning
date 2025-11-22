module ApiVersion::ApiVersionable
  extend ActiveSupport::Concern

  included do
    after_action :apply_version_transform
  end

  private

  def apply_version_transform
    return unless response.media_type == "application/json"

    version_files = ApiVersion.from_request(request)
    body = JSON.parse(response.body, symbolize_names: true)

    transformed = ApiVersion::ApiTransformations::Transformation.apply_response(controller_name, body, version_files)

    response.body = transformed.to_json

    response.headers['Content-Length'] = response.body.bytesize.to_s if response.headers['Content-Length']
  end
end
