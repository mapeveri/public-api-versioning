module ApiVersion
  CURRENT_VERSION = "2025-11-01"

  def self.from_request(request)
    request.headers["X-API-Version"] || CURRENT_VERSION
  end
end
