module Flipflop
  module Strategies
    class TestStrategy < AbstractStrategy
      @@lock = Mutex.new

      def initialize(**options)
        @features = {}
        super(**options)
      end

      def switchable?(feature)
        true
      end

      def enabled?(feature)
        @@lock.synchronize do
          @features[feature]
        end
      end

      def switch!(feature, enabled)
        @@lock.synchronize do
          @features[feature] = enabled
        end
      end

      def clear!(feature)
        @@lock.synchronize do
          @features.delete(feature)
        end
      end

      def reset!
        @@lock.synchronize do
          @features.clear
        end
      end
    end
  end
end
