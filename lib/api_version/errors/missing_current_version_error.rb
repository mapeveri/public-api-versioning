# lib/api_version/errors/missing_current_version_error.rb
module ApiVersion
  module Errors
    class MissingCurrentVersionError < StandardError
      def initialize
        super("[API_VERSION] Missing configuration: please set `Rails.application.config.x.api_current_version`")
      end
    end
  end
end
