module Flipflop
  class FeatureError < StandardError
    def initialize(key, error)
      super("Feature '#{key}' #{error}.")
    end
  end

  class StrategyError < StandardError
    def initialize(key, error)
      super("Strategy '#{key}' #{error}.")
    end
  end

  class Callback < StandardError
    def initialize(key, error)
      super("Callback '#{key}' #{error}.")
    end
  end

  class FeatureSet
    @@lock = Monitor.new

    class << self
      def current
        @current or @@lock.synchronize { @current ||= new }
      end

      private :new
    end

    attr_accessor :raise_strategy_errors

    def initialize
      @features = {}
      @strategies = {}
    end

    def configure(&block)
      Module.new do
        extend Configurable
        instance_exec(&block)
      end
      self
    end

    def replace
      @@lock.synchronize do
        initialize
        yield if block_given?
        @features.freeze
        @strategies.freeze
      end
      self
    end

    def test!(strategy = Strategies::TestStrategy.new)
      @@lock.synchronize do
        @strategies = { strategy.key => strategy.freeze }.freeze
      end
      strategy
    end

    def add(feature)
      @@lock.synchronize do
        if @features.has_key?(feature.key)
          raise FeatureError.new(feature.key, "already defined")
        end
        @features[feature.key] = feature.freeze
      end
    end

    def use(strategy)
      @@lock.synchronize do
        if @strategies.has_key?(strategy.key)
          raise StrategyError.new(strategy.name, "(#{strategy.class}) already defined with identical options")
        end
        @strategies[strategy.key] = strategy.freeze
      end
    end

    def enabled?(feature_key)
      FeatureCache.current.fetch(feature_key) do
        feature = feature(feature_key)

        result = @strategies.each_value.inject(nil) do |status, strategy|
          break status unless status.nil?
          strategy.enabled?(feature_key)
        end

        result.nil? ? feature.default : result
      end
    end

    def feature(feature_key)
      @features.fetch(feature_key) do
        raise FeatureError.new(feature_key, "unknown")
      end
    end

    def features
      @features.values
    end

    def strategy(strategy_key)
      @strategies.fetch(strategy_key) do
        raise StrategyError.new(strategy_key, "unknown")
      end
    end

    def strategies
      @strategies.values
    end

    def switch!(feature_key, strategy_key, value)
      strategy = strategy(strategy_key)
      feature = feature(feature_key)

      strategy.switch!(feature.key, value)
    end

    def clear!(feature_key, strategy_key)
      strategy = strategy(strategy_key)
      feature = feature(feature_key)

      strategy.clear!(feature.key)
    end
  end
end
