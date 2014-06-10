module ApiHammer
  module ActiveRecord
    module FindWithCaching
      def self.included(klass)
        klass.instance_eval do
          extend ClassMethods
          @caches_to_flush ||= []
          after_update :flush_cache
        end
      end

      module ClassMethods
        # overrides the given finder - either :find, or a dynamic matcher such as :find_by_name, :find_by_id
        #
        # causes the record that would be returned from the finder to be cached in Rails.cache 
        #
        # adds a after_update hook to clear the record from the cache.
        #
        # adds a method #flush_cache which may also be called to flush the cache. 
        def cache_finder(find_method_name)
          # determine find_attribute_names associated with the given find_method_name
          if find_method_name == :find
            find_attribute_names = [self.primary_key]
          elsif (matcher=::ActiveRecord::DynamicFinderMatch.match(find_method_name))
            raise NotImplementedError if matcher.instantiator? # not implemented for find_or_create_by_* or find_or_initialize_by_*
            raise NotImplementedError unless [:first, :last].include?(matcher.finder) # not implemented for find_all_by_*
            find_attribute_names = matcher.attribute_names
          else
            raise ArgumentError, "cannot determine attributes for finder method #{find_method_name}"
          end

          cache_key_prefix = [self.table_name, find_method_name]

          # redefine the method with caching, calling to super as appropriate 
          (class << self; self; end).send(:define_method, find_method_name) do |*find_args, &block|
            # the key is composed of the find arguments.
            # caching does not happen if there are more find arguments than find attributes (ie, there are other options or restrictions on the query)
            # caching does not happen if an argument isn't a string or number (e.g. find(:all), find([7, 17]))
            if !block && find_args.size == find_attribute_names.size && find_args.all?{|arg| arg.is_a?(String) || arg.is_a?(Numeric) }
              cache_key = (cache_key_prefix + find_args).join('/')
              ::Rails.cache.fetch(cache_key) do
                super(*find_args, &block)
              end
            else
              super(*find_args, &block)
            end
          end

          # add this to caches which will be flushed after_update 
          @caches_to_flush << {:cache_key_prefix => cache_key_prefix, :find_attribute_names => find_attribute_names}
        end
      end

      # clears this record from any caches in which it is stored 
      def flush_cache
        self.class.instance_variable_get(:@caches_to_flush).each do |cache_to_flush|
          key = (cache_to_flush[:cache_key_prefix] + cache_to_flush[:find_attribute_names].map{|attr_name| self[attr_name] }).join('/')
          ::Rails.cache.delete(key)
        end
        nil
      end
    end
  end
end
