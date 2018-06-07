module Flipflop
  module Strategies
    class ActiveRecordStrategy < AbstractStrategy
      class << self
        def default_description
          "Stores features in database. Applies to all users."
        end
      end

      def initialize(**options)
        @class = options.delete(:class) || ::Flipflop::Feature
        if !@class.kind_of?(Class)
          @class = ActiveSupport::Inflector.constantize(@class.to_s)
        end
        super(**options)
      end

      def switchable?(feature)
        true
      end

      def enabled?(feature)
        find(feature).first.try(:enabled?)
      end

      def switch!(feature, enabled)
        record = find(feature).first_or_initialize
        record.enabled = enabled
        record.save!
      end

      def clear!(feature)
        find(feature).first.try(:destroy)
      end

      protected

      def find(feature)
        @class.where(key: feature.to_s)
      end
    end
  end
end
