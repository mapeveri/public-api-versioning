module ApiVersion
  require_relative "concerns/api_versionable"

  def self.from_request(request)
    version = request.headers["X-API-Version"] || current_version

    puts version
    (Rails.application.config.x.version_files[version] || []).map do |class_name|
      class_name.constantize
    end
  end

  private 

    def self.current_version
      api_current_version = Rails.application.config.x.api_current_version

      if !api_current_version.is_a?(String) || api_current_version.blank?
        raise Errors::MissingCurrentVersionError.new
      end

      api_current_version
    end
end
