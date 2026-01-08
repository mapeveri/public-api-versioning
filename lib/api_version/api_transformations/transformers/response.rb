module ApiVersion
  module ApiTransformations
    module Transformation
      module Response
        def self.apply(controller_name, body, version_files)
          if body.is_a?(Array)
            return body.map { |item| apply(controller_name, item, version_files) }
          end

          version_files = ApiTransformations::VersionFilesFinder.find(controller_name, version_files)
          version_files_desc_order = version_files.reverse

          version_files_desc_order.each do |version_class|
            next unless version_class.send(:response_block)

            builder = ApiVersion::ApiTransformations::TransformationBuilder.new(body)
            version_class.send(:response_block).call(builder)
            body = builder.build
          end

          body
        end
      end
    end
  end
end
