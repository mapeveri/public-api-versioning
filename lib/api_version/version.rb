module ApiVersion
  class Version
    class << self
      attr_reader :resource_name, :timestamp_value

      def timestamp(value)
        @timestamp_value = value
      end

      def resource(name)
        @resource_name = name.to_sym
      end
    end

    def change_set
      raise NotImplementedError, "You must implement #change_set"
    end
  end
end
