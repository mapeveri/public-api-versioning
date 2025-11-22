module ApiVersion
  module Middlewares
    class TransformRequestPayload
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        if request.media_type == "application/json" && request.body.size > 0
          begin
            body = JSON.parse(request.body.read, symbolize_names: true)
            request.body.rewind

            version_files = ApiVersion.from_request(request)
            controller_name = request.path.split("/").last
            transformed = ApiVersion::ApiTransformations::Transformation.apply_payload(
              controller_name,
              body,
              version_files
            )

            transformed_json = transformed.to_json
            env["rack.input"] = StringIO.new(transformed_json)
            env["CONTENT_LENGTH"] = transformed_json.bytesize.to_s
          rescue JSON::ParserError
            # If parsing fails, we leave the body unchanged
          end
        end

        @app.call(env)
      end
    end
  end
end
