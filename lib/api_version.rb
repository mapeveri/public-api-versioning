module ApiVersion
  require_relative "api_version/main"
  require_relative "api_version/middlewares/transform_request_payload"
  require_relative "api_version/railtie" if defined?(Rails)
end
