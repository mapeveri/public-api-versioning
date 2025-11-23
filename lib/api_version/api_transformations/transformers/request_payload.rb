module ApiVersion
  module ApiTransformations
    module Transformation
      module RequestPayload
        def self.apply(controller_name, params, version_files)
          if params.is_a?(Array)
            return params.map { |item| apply(controller_name, item, version_files) }
          end

          version_files = ApiTransformations::VersionFilesFinder.find(controller_name, version_files)

          version_files.each do |version_class|
            next unless version_class.send(:payload_block)

            resource_key = controller_name.to_s.singularize.to_sym
            target_data = if params.is_a?(Hash) && params.key?(resource_key)
              params[resource_key]
            else
              params
            end

            builder = ApiVersion::ApiTransformations::TransformationBuilder.new(target_data)
            version_class.send(:payload_block).call(builder)

            if params.is_a?(Hash) && params.key?(resource_key)
              params[resource_key] = builder.build
            else
              params = builder.build
            end
          end

          params
        end
      end
    end
  end
end
