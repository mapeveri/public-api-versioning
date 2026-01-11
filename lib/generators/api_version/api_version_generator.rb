require "rails/generators"
require "fileutils"

class ApiVersionGenerator < Rails::Generators::Base
  argument :resource, type: :string
  class_option :path, type: :string, default: nil, desc: "Custom path for version file (e.g., app/controllers/api/v2/versions)"
  class_option :namespace, type: :string, default: nil, desc: "API namespace (e.g., v1, v2)"

  source_root File.expand_path("templates", __dir__)

  def create_version_file
    @timestamp = Time.now.strftime("%Y%m%d%H%M")
    @resource = resource

    @base_path = options[:path] || "app/controllers/versions"
    FileUtils.mkdir_p(@base_path) unless Dir.exist?(@base_path)

    @namespace = options[:namespace] || path_to_namespace(@base_path)
    @class_name = "Version#{@timestamp}#{resource.camelize}"
    file_name = "#{@class_name.underscore}.rb"

    template "version.rb.tt", File.join(@base_path, file_name)
  end

  private

  def path_to_namespace(path)
    # 1. Try to match any configured namespace in the path
    if defined?(Rails) && Rails.application.config.x.respond_to?(:api_current_versions)
      keys = Rails.application.config.x.api_current_versions.keys
      match = keys.find { |k| path.include?("/#{k}/") }
      return match if match
    end

    # 2. Fallback to v\d+ pattern in path
    match = path.match(/api\/(v\d+)/)
    return match[1] if match

    # 3. No match found, return nil (no namespace)
    nil
  end
end
