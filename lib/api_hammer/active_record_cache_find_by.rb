module ActiveRecord
  class Relation
    unless method_defined?(:first_without_caching)
      alias_method :first_without_caching, :first
      def first(*args)
        actual_right = proc do |where_value|
          if where_value.right.is_a?(Arel::Nodes::BindParam)
            column, value = bind_values.detect { |(column, value)| column.name == where_value.left.name }
            value
          else
            where_value.right
          end
        end
        cache_find_by = klass.instance_eval { @cache_find_by }
        can_cache = cache_find_by &&
          args.empty? && # no array result, only the actual first
          !loaded? && # if it's loaded no need to hit cache 
          where_values.all? { |wv| wv.is_a?(Arel::Nodes::Equality) } && # no inequality or that sort of thing 
          cache_find_by.include?(where_values.map { |wv| wv.left.name }.sort) && # any of the set of where-values to cache match this relation 
          where_values.map(&actual_right).all? { |r| r.is_a?(String) || r.is_a?(Numeric) } && # check all right side values are simple types, number or string 
          offset_value.nil? &&
          joins_values.blank? &&
          order_values.blank? &&
          includes_values.blank? &&
          preload_values.blank? &&
          select_values.blank? &&
          group_values.blank?

        if can_cache
          cache_key_prefix = ['cache_find_by', table.name]
          find_attributes = where_values.sort_by { | wv| wv.left.name }.map { |wv| [wv.left.name, actual_right.call(wv)] }.inject([], &:+)
          cache_key = (cache_key_prefix + find_attributes).join('/')
          ::Rails.cache.fetch(cache_key) do
            first_without_caching(*args)
          end
        else
          first_without_caching(*args)
        end
      end
    end
  end

  class Base
    class << self
      def cache_find_by(*attribute_names)
        unless @cache_find_by
          # initial setup
          @cache_find_by = Set.new
          after_update :flush_find_cache
        end
        @cache_find_by << attribute_names.map { |n| n.is_a?(Symbol) ? n.to_s : n.is_a?(String) ? n : raise(ArgumentError) }.sort
      end
    end

    def flush_find_cache
      self.class.instance_eval { @cache_find_by }.each do |attribute_names|
        cache_key_prefix = ['cache_find_by', self.class.table_name]
        find_attributes = attribute_names.map { |attr_name| [attr_name, self.send(:attribute_was, attr_name)] }.inject([], &:+)
        cache_key = (cache_key_prefix + find_attributes).join('/')
        ::Rails.cache.delete(cache_key)
      end
      nil
    end
  end
end
