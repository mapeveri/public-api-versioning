module ApiVersion
  module TestHelpers
    def transform_payload(payload, version:, resource:, namespace: nil)
      ApiVersion.load_versions
      
      version_classes = ApiVersion::Version.all_versions.select do |v|
        v.namespace_value == (namespace&.to_s) && v.timestamp_value >= version
      end.sort_by(&:timestamp_value)

      ApiVersion::ApiTransformations::Transformation::RequestPayload.apply(
        resource,
        payload,
        version_classes
      )
    end

    def transform_response(body, version:, resource:, namespace: nil)
      ApiVersion.load_versions

      version_classes = ApiVersion::Version.all_versions.select do |v|
        v.namespace_value == (namespace&.to_s) && v.timestamp_value >= version
      end.sort_by(&:timestamp_value).reverse

      ApiVersion::ApiTransformations::Transformation::Response.apply(
        resource,
        body,
        version_classes
      )
    end
  end
end
