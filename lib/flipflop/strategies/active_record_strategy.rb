module Flipflop
  module Strategies
    class ActiveRecordStrategy < AbstractStrategy
      class << self
        def default_description
          "Stores features in database. Applies to all users."
        end

        def define_feature_class
          return Flipflop::Feature if defined?(Flipflop::Feature)

          model = Class.new(ActiveRecord::Base)
          Flipflop.const_set(:Feature, model)
        end
      end

      def initialize(**options)
        @class = options.delete(:class) || self.class.define_feature_class
        @eager = options.delete(:eager) || false
        if !@class.kind_of?(Class)
          @class = ActiveSupport::Inflector.constantize(@class.to_s)
        end
        super(**options)
      end

      def switchable?(feature)
        true
      end

      def enabled?(feature)
        cache = FeatureCache.current if @eager
        if cache
          cache.fetch(key) { all_features }[feature]
        else
          scoped(feature).first.try(:enabled?)
        end
      end

      def switch!(feature, enabled)
        record = scoped(feature).first_or_initialize
        record.enabled = enabled
        record.save!
      end

      def clear!(feature)
        scoped(feature).first.try(:destroy)
      end

      protected

      def scoped(feature)
        @class.where(key: feature.to_s)
      end

      def all_features
        @class.all.to_h { |feature| [feature.key.to_sym, feature.enabled?] }
      end
    end
  end
end
