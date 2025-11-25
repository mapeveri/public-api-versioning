# Set current stable version
# For single API:
Rails.application.config.x.api_current_version = "2025-11-01"

# For multiple APIs (v1, v2, etc.), use this instead:
# Rails.application.config.x.api_current_versions = {
#   "v1" => "2025-03-01",
#   "v2" => "2025-11-01"
# }

# Define version files for each API version
Rails.application.config.x.version_files = {
  "2025-01-01" => [ "Api::V1::Versions::Version202501010001CombineFirstAndLastNameToNameInUser" ],
  "2025-11-01" => []
}
