module ApiVersion::ApiVersionable
  extend ActiveSupport::Concern

  included do
    rescue_from ApiVersion::Errors::InvalidVersionError, with: :handle_invalid_version
    before_action :check_endpoint_status
    after_action :apply_version_transform
  end

  private

  def handle_invalid_version(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def check_endpoint_status
    version_files = ApiVersion.from_request(request, self)
    return if version_files.empty?

    version_files.each do |version_class|
      if version_class.removed_endpoints&.any? { |e| e[:controller] == controller_name && e[:action] == action_name }
        render json: { error: "Gone" }, status: :gone
        return
      end

      if version_class.deprecated_endpoints&.any? { |e| e[:controller] == controller_name && e[:action] == action_name }
        response.headers["Warning"] = "299 - Endpoint Deprecated"
      end
    end
  end

  def apply_version_transform
    return unless response.media_type == "application/json"

    version_files = ApiVersion.from_request(request, self)
    return if version_files.empty?

    body = JSON.parse(response.body, symbolize_names: true)

    transformed = ApiVersion::ApiTransformations::Transformation::Response.apply(controller_name, body, version_files)

    response.body = transformed.to_json

    response.headers["Content-Length"] = response.body.bytesize.to_s if response.headers["Content-Length"]
  end
end
