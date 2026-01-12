module ApiVersion
  require_relative "api_version/configuration"
  require_relative "api_version/main"
  require_relative "api_version/middlewares/transform_request_payload"
  require_relative "api_version/railtie" if defined?(Rails)


  require_relative "api_version/api_transformations/transformation_builder"
  require_relative "api_version/api_transformations/version_files_finder"
  require_relative "api_version/api_transformations/transformers/request_payload"
  require_relative "api_version/api_transformations/transformers/response"
  require_relative "api_version/test_helpers"

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.config
    configuration
  end

  def self.configure
    yield(configuration)
  end
end
