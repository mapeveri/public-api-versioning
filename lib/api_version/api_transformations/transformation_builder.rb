module ApiVersion
  class ApiTransformations::TransformationBuilder
    attr_reader :item

    def initialize(item)
      @item = item.is_a?(Hash) ? item.deep_symbolize_keys : item
    end

    def add_field(field, _type = nil)
      @item[field.to_sym] ||= nil
    end

    def remove_field(field)
      @item.delete(field.to_sym)
    end

    def rename_field(old_field, new_field)
      old_k = old_field.to_sym
      new_k = new_field.to_sym
      @item[new_k] = @item.delete(old_k) if @item.key?(old_k)
    end

    def split_field(field, into:)
      values = @item[field.to_sym]&.to_s&.split(" ")
      return unless values
      into.each_with_index { |f, i| @item[f.to_sym] = values[i] }
      @item.delete(field.to_sym)
    end

    def transform(field_name, &block)
      @item[field_name] = block.call(@item)
    end

    def build
      @item
    end
  end
end
