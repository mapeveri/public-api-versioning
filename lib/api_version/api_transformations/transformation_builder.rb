module ApiVersion
  class ApiTransformations::TransformationBuilder
    attr_reader :item

    def initialize(item)
      @item = item.is_a?(Hash) ? item.deep_symbolize_keys : item
    end

    def add_field(field, _legacy_type = nil, default: nil, &block)
      value = if block_given?
                block.call(@item)
              else
                default
              end
      @item[field.to_sym] = value
    end

    def change_to_mandatory(field, default: nil, &block)
      if @item[field.to_sym].nil?
        value = if block_given?
                  block.call(@item)
                else
                  default
                end
        @item[field.to_sym] = value
      end
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
