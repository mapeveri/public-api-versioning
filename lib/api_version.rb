module ApiVersion
  require_relative "api_version/main"
  require_relative "api_version/middlewares/transform_request_payload"
  require_relative "api_version/railtie" if defined?(Rails)



  require_relative "api_version/api_transformations/transformation_builder"
  require_relative "api_version/api_transformations/version_files_finder"
  require_relative "api_version/api_transformations/transformers/request_payload"
  require_relative "api_version/api_transformations/transformers/response"
end
