module ApiVersion
  require_relative "concerns/api_versionable"

  def self.from_request(request, controller = nil)
    version = request.headers["X-API-Version"] || current_version(controller)

    namespace = detect_api_version_from_path(controller, Rails.application.config.x.api_current_versions.keys)

    api_version_files = Rails.application.config.x.version_files[namespace] || {}

    if request.headers["X-API-Version"] && !api_version_files.key?(version)
      raise Errors::InvalidVersionError.new(version, namespace, api_version_files.keys)
    end

    (api_version_files[version] || []).map do |class_name|
      class_name.constantize
    end
  end

  private

    def self.current_version(controller = nil)
      unless Rails.application.config.x.respond_to?(:api_current_versions) &&
             Rails.application.config.x.api_current_versions.is_a?(Hash)
        raise Errors::MissingCurrentVersionError.new
      end

      versions = Rails.application.config.x.api_current_versions

      if controller
        namespace = detect_api_version_from_path(controller, versions.keys)
        return versions[namespace] if namespace && versions[namespace]
      end

      raise Errors::MissingCurrentVersionError.new
    end

    def self.detect_api_version_from_path(controller, version_keys)
      path = controller.request.path
      version_keys.find { |key| path.include?("/#{key}/") }
    end
end
