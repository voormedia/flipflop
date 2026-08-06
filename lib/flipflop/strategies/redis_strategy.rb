module Flipflop
  module Strategies
    class RedisStrategy < AbstractStrategy
      class << self
        def default_description
          "Stores features in Redis. Applies to all users."
        end
      end

      def initialize(**options)
        @client = options.delete(:client) || ::Redis.new
        @prefix = options.delete(:prefix).to_s.freeze
        super(**options)
      end

      def switchable?(feature)
        true
      end

      def enabled?(feature)
        redis_value = @client.get(redis_key(feature))
        return if redis_value.nil?
        redis_value === "1"
      end

      def switch!(feature, enabled)
        @client.set(redis_key(feature), enabled ? "1" : "0")
      end

      def clear!(feature)
        @client.del(redis_key(feature))
      end

      protected

      def redis_key(feature)
        @prefix + feature.to_s
      end
    end
  end
end
