module ApiVersion
  module ApiTransformations::Transformation
    def self.apply_transformations(controller_name, body, version_files)
      return body if version_files.empty?

      if body.is_a?(Array)
        return body.map { |item| apply_transformations(controller_name, item, version_files) }
      end

      version_classes = version_files.map do |entry|
        entry.is_a?(String) ? entry.constantize : entry
      end

      version_classes.select! do |klass|
        klass.is_a?(Class) && klass < ApiVersion::Version
      end

      relevant_versions = version_classes.select do |klass|
        klass.resource_name == controller_name.to_sym
      end

      return body if relevant_versions.empty?

      relevant_versions.sort_by(&:timestamp_value).each do |version_class|
        builder = ApiVersion::ApiTransformations::TransformationBuilder.new(body)
        version_class.new.change_set.call(builder)
        body = builder.build
      end

      body
    end
  end
end
