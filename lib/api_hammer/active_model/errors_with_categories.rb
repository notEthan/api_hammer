module ApiHammer
  module ActiveModel
    module Validations
      module ClassMethodsWithCategory
        # adds :category to the default keys that are passed from #validates arguments to the individual
        # validators, so that you can do something like
        #
        #     validates :uuid, format: /\A\w+\z/, category: :INVALID_PARAMETERS
        #
        # instead of putting the category in in the parameters to the validator like:
        #
        #     validates :name, format: {with: /\A\w+\z/, category: :INVALID_PARAMETERS}
        #
        # (though of course the latter works as well)
        def _validates_default_keys
          super + [:category]
        end
      end

      # the presence validator has a default category of MISSING_PARAMETERS, since that is most probably
      # what a non-present attribute indicates. this can be overridden as usual with the :category option.
      module PresenceValidatorWithCategory
        def initialize(options = {})
          options[:category] ||= 'MISSING_PARAMETERS'
          super
        end
      end
    end

    # adds #categories to ActiveModel::Errors
    module ErrorsWithCategories
      attr_accessor :categories
      def initialize(*)
        super
        @categories = {}
      end
      def initialize_dup(other)
        super
        @categories = other.categories.dup
      end
      def clear
        super
        categories.clear
      end
      def delete(key)
        super
        categories.delete(key)
      end
      def add(attribute, message = :invalid, options = {})
        super
        if options[:category]
          categories[attribute] = (categories[attribute] || []) | [options[:category]]
        end
      end
    end
  end
end

require 'active_model'
module ActiveModel
  module Validations
    # since ActiveRecord::Base and perhaps other ActiveModel inheritors are already loaded, need to prepend
    # into each of them in addition to ActiveModel::Validations::ClassMethods
    ObjectSpace.each_object(Class).select { |k| k.singleton_class < ClassMethods }.each do |k|
      k.singleton_class.prepend(ApiHammer::ActiveModel::Validations::ClassMethodsWithCategory)
    end
    ClassMethods.prepend(ApiHammer::ActiveModel::Validations::ClassMethodsWithCategory)

    PresenceValidator.prepend(ApiHammer::ActiveModel::Validations::PresenceValidatorWithCategory)
  end

  Errors.prepend(ApiHammer::ActiveModel::ErrorsWithCategories)
end
