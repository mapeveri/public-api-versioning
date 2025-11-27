# Set current stable version
Rails.application.config.x.api_current_versions = {
  "v1" => "2025-11-01",
  "v2" => "2025-11-27"
}

# Define version files for each API version
Rails.application.config.x.version_files = {
  "v1" => {
    "2025-01-01" => [ "Api::V1::Versions::Version202501010001CombineFirstAndLastNameToNameInUser" ],
    "2025-11-01" => []
  },
  "v2" => {
    "2025-11-27" => [ "Api::V2::Versions::Version202511270001Users" ]
  }
}
