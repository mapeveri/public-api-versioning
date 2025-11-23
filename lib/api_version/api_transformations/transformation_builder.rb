module ApiVersion
  module ApiTransformations
    class TransformationBuilder
      attr_reader :item

      def initialize(item)
        @item = item.is_a?(Hash) ? item.deep_symbolize_keys : item
      end

      def add_field(field, _legacy_type = nil, default: nil)
        key = field.to_sym
        @item[key] = block_given? ? yield(@item) : default
      end

      def change_to_mandatory(field, default: nil)
        key = field.to_sym
        return unless @item[key].nil?

        @item[key] = block_given? ? yield(@item) : default
      end

      def remove_field(field)
        @item.delete(field.to_sym)
      end

      def rename_field(old_field, new_field)
        old_key = old_field.to_sym
        new_key = new_field.to_sym
        @item[new_key] = @item.delete(old_key) if @item.key?(old_key)
      end

      def split_field(field, into:)
        values = @item[field.to_sym]&.to_s&.split(" ")
        return unless values
        into.each_with_index { |f, i| @item[f.to_sym] = values[i] }
        @item.delete(field.to_sym)
      end

      def combine_fields(*fields, into:, &block)
        values = fields.map { |f| @item[f.to_sym] }
        @item[into.to_sym] = block.call(*values)
        fields.each { |f| @item.delete(f.to_sym) }
      end

      def transform(field_name, &block)
        @item[field_name] = block.call(@item)
      end

      def nest(field)
        key = field.to_sym
        return unless @item[key].is_a?(Hash)

        builder = self.class.new(@item[key])
        yield(builder)
        @item[key] = builder.build
      end

      def each(field)
        key = field.to_sym
        return unless @item[key].is_a?(Array)

        @item[key] = @item[key].map do |element|
          builder = self.class.new(element)
          yield(builder)
          builder.build
        end
      end

      def move_field(field, to:)
        key = field.to_sym
        return unless @item.key?(key)

        value = @item.delete(key)
        target_path = Array(to).map(&:to_sym)
        last_key = target_path.pop

        target = @item
        target_path.each do |path_key|
          target[path_key] ||= {}
          target = target[path_key]
        end

        target[last_key] = value
      end

      def build
        @item
      end
    end
  end
end
