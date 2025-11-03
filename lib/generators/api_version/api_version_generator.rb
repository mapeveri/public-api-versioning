require "rails/generators"
require "fileutils"

class ApiVersionGenerator < Rails::Generators::Base
  argument :resource, type: :string

  source_root File.expand_path("templates", __dir__)

  def create_version_file
    @timestamp = Time.now.strftime("%Y%m%d%H%M")
    @resource = resource

    @base_path = Rails.application.config.api_version_base_path || "app/versions"
    FileUtils.mkdir_p(@base_path) unless Dir.exist?(@base_path)

    @namespace = path_to_namespace(@base_path)
    @class_name = "Version#{@timestamp}#{resource.camelize}"
    file_name = "#{@class_name.underscore}.rb"

    template "version.rb.tt", File.join(@base_path, file_name)
  end

  private

  def path_to_namespace(path)
    relative = path.sub(/^app\/(controllers\/)?/, "")
    parts = relative.split("/")
    parts.map { |part| part.camelize }.join("::")
  end
end
