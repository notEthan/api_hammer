module ActiveRecord
  class Relation
    if !method_defined?(:first_without_caching)
      alias_method :first_without_caching, :first
      def first(*args)
        one_record_with_caching(args.empty?) { first_without_caching(*args) }
      end
    end
    if !method_defined?(:take_without_caching) && method_defined?(:take)
      alias_method :take_without_caching, :take
      def take(*args)
        one_record_with_caching(args.empty?) { take_without_caching(*args) }
      end
    end

    # retrieves one record, hitting the cache if appropriate. the argument may bypass caching 
    # (the caller could elect to just not call this method if caching is to be avoided, but since this 
    # method already builds in opting whether or not to hit cache, the code is simpler just passing that in).
    #
    # requires a block which returns the record 
    def one_record_with_caching(can_cache = true)
      actual_right = proc do |where_value|
        if where_value.right.is_a?(Arel::Nodes::BindParam)
          column, value = bind_values.detect { |(column, value)| column.name == where_value.left.name }
          value
        else
          where_value.right
        end
      end
      cache_find_bys = klass.cache_find_bys
      can_cache &&= cache_find_bys &&
        !loaded? && # if it's loaded no need to hit cache 
        where_values.all? { |wv| wv.is_a?(Arel::Nodes::Equality) } && # no inequality or that sort of thing 
        cache_find_bys.include?(where_values.map { |wv| wv.left.name }.sort) && # any of the set of where-values to cache match this relation 
        where_values.map(&actual_right).all? { |r| r.is_a?(String) || r.is_a?(Numeric) } && # check all right side values are simple types, number or string 
        offset_value.nil? &&
        joins_values.blank? &&
        order_values.blank? &&
        !reverse_order_value &&
        includes_values.blank? &&
        preload_values.blank? &&
        select_values.blank? &&
        group_values.blank? &&
        from_value.nil? &&
        lock_value.nil?

      if can_cache
        cache_key_prefix = ['cache_find_by', table.name]
        find_attributes = where_values.sort_by { | wv| wv.left.name }.map { |wv| [wv.left.name, actual_right.call(wv)] }.inject([], &:+)
        cache_key = (cache_key_prefix + find_attributes).join('/')
        klass.finder_cache.fetch(cache_key) do
          yield
        end
      else
        yield
      end
    end
  end

  class Base
    class << self
      def finder_cache=(val)
        define_singleton_method(:finder_cache) { val }
      end

      # the cache. should be an instance of some sort of ActiveSupport::Cache::Store. 
      # by default uses Rails.cache if that exists, or creates a ActiveSupport::Cache::MemoryStore to use. 
      # set this per-model or on ActiveRecord::Base, as needed; it is inherited. 
      def finder_cache
        # dummy; this gets set below 
      end

      def cache_find_bys=(val)
        define_singleton_method(:cache_find_bys) { val }
      end

      def cache_find_bys
        nil
      end

      # causes requests to retrieve a record by the given attributes (all of them) to be cached. 
      # this is for single records only. it is unsafe to use with a set of attributes whose values 
      # (in conjunction) may be associated with multiple records. 
      #
      # see .finder_cache and .find_cache= for where it is cached. 
      #
      # #flush_find_cache is defined on the instance. it is called on save to clear an updated record from 
      # the cache. it may also be called explicitly to clear a record from the cache. 
      #
      # beware of multiple application servers with different caches - a record cached in multiple will not 
      # be invalidated in all when it is saved in one.
      def cache_find_by(*attribute_names)
        unless cache_find_bys
          # initial setup
          self.cache_find_bys = Set.new
          after_update :flush_find_cache
          before_destroy :flush_find_cache
        end

        find_by = attribute_names.map do |name|
          raise(ArgumentError) unless name.is_a?(Symbol) || name.is_a?(String)
          name.to_s.dup.freeze
        end.sort.freeze

        self.cache_find_bys = (cache_find_bys | [find_by]).freeze
      end
    end

    # the above dummy method has no content because we want to evaluate this now, not in the method, to 
    # avoid instantiating duplicate MemoryStores. 
    self.finder_cache = (Object.const_defined?(:Rails) && ::Rails.cache) || ::ActiveSupport::Cache::MemoryStore.new

    # clears this record from the cache used by cache_find_by
    def flush_find_cache
      self.class.cache_find_bys.each do |attribute_names|
        cache_key_prefix = ['cache_find_by', self.class.table_name]
        find_attributes = attribute_names.map { |attr_name| [attr_name, self.send(:attribute_was, attr_name)] }.inject([], &:+)
        cache_key = (cache_key_prefix + find_attributes).join('/')
        self.class.finder_cache.delete(cache_key)
      end
      nil
    end
  end
end
