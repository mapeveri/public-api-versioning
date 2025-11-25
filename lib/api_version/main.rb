module ApiVersion
  require_relative "concerns/api_versionable"

  def self.from_request(request, controller = nil)
    version = request.headers["X-API-Version"] || current_version(controller)

    (Rails.application.config.x.version_files[version] || []).map do |class_name|
      class_name.constantize
    end
  end

  private

    def self.current_version(controller = nil)
      # Try multi-API config first
      if Rails.application.config.x.respond_to?(:api_current_versions)
        versions = Rails.application.config.x.api_current_versions
        if versions.is_a?(Hash) && controller
          namespace = extract_api_namespace(controller)
          return versions[namespace] if namespace && versions[namespace]
        end
      end

      # Fall back to single API config (backward compatible)
      api_current_version = Rails.application.config.x.api_current_version

      if !api_current_version.is_a?(String) || api_current_version.blank?
        raise Errors::MissingCurrentVersionError.new
      end

      api_current_version
    end

    def self.extract_api_namespace(controller)
      # Api::V1::UsersController → "v1"
      # Api::V2::ProductsController → "v2"
      parts = controller.class.name.split("::")
      parts[1]&.downcase if parts.length >= 2
    end
end
