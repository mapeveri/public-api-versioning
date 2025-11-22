module ApiVersion
  class Railtie < ::Rails::Railtie
    initializer "api_version.insert_middleware" do |app|
      app.middleware.use ApiVersion::Middlewares::TransformRequestPayload
    end
  end
end
