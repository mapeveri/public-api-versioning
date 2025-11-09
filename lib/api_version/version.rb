module ApiVersion
  class Version
    class << self
      attr_reader :resource_name, :timestamp_value, :payload_block, :response_block

      def timestamp(value)
        @timestamp_value = value
      end

      def resource(name)
        @resource_name = name.to_sym
      end

      def payload(&block)
        @payload_block = block
      end

      def response(&block)
        @response_block = block
      end
    end
  end
end
