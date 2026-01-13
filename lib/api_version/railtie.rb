module ApiVersion
  class Railtie < ::Rails::Railtie
    initializer "api_version.configure" do |app|
      ApiVersion.configure do |config|
        if app.config.respond_to?(:x) && app.config.x.respond_to?(:api_current_versions)
          config.api_current_versions = app.config.x.api_current_versions
        end
        # Use default path or sync if previously configured via some other means (unlikely but safe)
        if app.config.respond_to?(:x) && app.config.x.respond_to?(:api_version_files_path)
           config.version_files_path = app.config.x.api_version_files_path
        end
      end
    end

    initializer "api_version.insert_middleware" do |app|
      app.middleware.use ApiVersion::Middlewares::TransformRequestPayload
    end
  end
end
