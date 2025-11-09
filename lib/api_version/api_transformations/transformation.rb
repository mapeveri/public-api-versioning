module ApiVersion
  module ApiTransformations::Transformation
    def self.apply_payload(controller_name, params, version_files)
      apply(controller_name, params, version_files, :payload_block)
    end

    def self.apply_response(controller_name, body, version_files)
      apply(controller_name, body, version_files, :response_block)
    end

    private
      def self.apply(controller_name, data, version_files, block_type)
        return data if version_files.empty?

        if data.is_a?(Array)
          return data.map { |item| apply(controller_name, item, version_files, block_type) }
        end

        version_classes = version_files.map { |v| v.is_a?(String) ? v.constantize : v }
        version_classes.select! { |klass| klass.is_a?(Class) && klass < ApiVersion::Version }
        relevant_versions = version_classes.select { |klass| klass.resource_name == controller_name.to_sym }

        return data if relevant_versions.empty?

        relevant_versions.sort_by(&:timestamp_value).each do |version_class|
          next unless version_class.send(block_type)

          builder = ApiVersion::ApiTransformations::TransformationBuilder.new(data)
          version_class.send(block_type).call(builder)
          data = builder.build
        end

        data
      end
  end
end
