module ApiVersion
  class Configuration
    attr_accessor :api_current_versions, :api_supported_versions, :version_files_path

    def initialize
      @api_current_versions = {}
      @api_supported_versions = {}
      @version_files_path = "app/controllers/**/versions/*.rb"
    end
  end
end
