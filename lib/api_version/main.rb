module ApiVersion
  require_relative "concerns/api_versionable"

  def self.from_request(request, controller = nil)
    requested_version = request.headers["X-API-Version"] || current_version(controller)
    return [] if requested_version.nil?

    version_keys = ApiVersion.config.api_current_versions.keys
    namespace = detect_api_version_from_path(controller || request, version_keys)

    load_versions

    available_versions = ApiVersion::Version.all_versions.select do |v|
      v.namespace_value == namespace
    end

    if request.headers["X-API-Version"]
      current = current_version(controller || request)
      if current && requested_version > current
        raise Errors::InvalidVersionError.new(requested_version, namespace, ["Current version: #{current}"])
      end
    end

    available_versions.select do |v|
      v.timestamp_value >= requested_version
    end
  end

  def self.load_versions
    return if @versions_loaded
    
    path = if defined?(Rails)
             Rails.root.join(ApiVersion.config.version_files_path).to_s
           else
             ApiVersion.config.version_files_path
           end

    Dir.glob(path).each do |file|
      require_dependency file
    end
    @versions_loaded = true
  end

  private

    def self.current_version(controller = nil)
      versions = ApiVersion.config.api_current_versions
      return nil if versions.empty?

      # If only one namespace is configured, use it as default
      return versions.values.first if versions.size == 1

      if controller
        namespace = detect_api_version_from_path(controller, versions.keys)
        return versions[namespace] if namespace && versions[namespace]
      end

      nil
    end

    def self.detect_api_version_from_path(source, version_keys)
      # Allow controller to explicitly define the namespace
      if source.respond_to?(:api_version_namespace)
        return source.api_version_namespace.to_s
      end

      # If only one namespace is configured, we don't strictly need it in the path
      return version_keys.first if version_keys.size == 1

      path = source.respond_to?(:request) ? source.request.path : source.path
      version_keys.find { |key| path.include?("/#{key}/") }
    end
end
