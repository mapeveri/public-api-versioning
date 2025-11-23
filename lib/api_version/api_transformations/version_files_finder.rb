module ApiVersion
  module ApiTransformations
    module VersionFilesFinder
      def self.find(controller_name, version_files)
        return [] if version_files.empty?

        version_classes = version_files.map { |v| v.is_a?(String) ? v.constantize : v }
        version_classes.select! { |klass| klass.is_a?(Class) && klass < ApiVersion::Version }
        relevant_versions = version_classes.select { |klass| klass.resource_name == controller_name.to_sym }

        relevant_versions.sort_by(&:timestamp_value)
      end
    end
  end
end
