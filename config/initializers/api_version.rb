# Set current stable version
Rails.application.config.x.api_current_version = "2025-11-01"

# Define version files for each API version
Rails.application.config.x.version_files = {
  "2025-01-01" => [ "Api::V1::Versions::Version202501010001CombineFirstAndLastNameToNameInUser" ],
  "2025-11-01" => []
}
