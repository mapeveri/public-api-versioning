module ApiVersion
  module Errors
    class InvalidVersionError < StandardError
      def initialize(version, namespace, available_versions)
        @version = version
        @namespace = namespace
        @available_versions = available_versions
        super(message)
      end

      def message
        "[API_VERSION] Invalid version '#{@version}' for API #{@namespace}. Available versions: #{@available_versions.join(', ')}"
      end
    end
  end
end
