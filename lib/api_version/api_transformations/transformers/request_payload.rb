module ApiVersion
  module ApiTransformations
    module Transformation
      module RequestPayload
        def self.apply(controller_name, body, version_files)
          if body.is_a?(Array)
            return body.map { |item| apply(controller_name, item, version_files) }
          end

          version_files = ApiTransformations::VersionFilesFinder.find(controller_name, version_files)

          version_files.each do |version_class|
            next unless version_class.send(:payload_block)

            resource_key = controller_name.to_s.singularize.to_sym
            target_data = if body.is_a?(Hash) && body.key?(resource_key)
              body[resource_key]
            else
              body
            end

            builder = ApiVersion::ApiTransformations::TransformationBuilder.new(target_data)
            version_class.send(:payload_block).call(builder)

            if body.is_a?(Hash) && body.key?(resource_key)
              body[resource_key] = builder.build
            else
              body = builder.build
            end
          end

          body
        end
      end
    end
  end
end
