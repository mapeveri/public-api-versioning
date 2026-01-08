module ApiVersion
  class Version
    class << self
      attr_reader :resource_name, :timestamp_value, :payload_block, :response_block, :removed_endpoints, :deprecated_endpoints, :namespace_value

      def inherited(subclass)
        super
        @subclasses ||= []
        @subclasses << subclass
      end

      def all_versions
        @subclasses || []
      end

      def clear_versions
        @subclasses = []
      end

      def timestamp(value)
        @timestamp_value = value
      end

      def resource(name)
        @resource_name = name.to_sym
      end

      def namespace(name)
        @namespace_value = name.to_s
      end

      def payload(&block)
        @payload_block = block
      end

      def response(&block)
        @response_block = block
      end

      def endpoint_removed(controller, action)
        @removed_endpoints ||= []
        @removed_endpoints << { controller: controller.to_s, action: action.to_s }
      end

      def endpoint_deprecated(controller, action)
        @deprecated_endpoints ||= []
        @deprecated_endpoints << { controller: controller.to_s, action: action.to_s }
      end
    end
  end
end
