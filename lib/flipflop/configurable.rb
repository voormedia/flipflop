module Flipflop
  module Configurable
    attr_accessor :current_group

    def group(group)
      self.current_group = GroupDefinition.new(group)
      yield
    ensure
      self.current_group = nil
    end

    def feature(feature, **options)
      options = options.merge(group: current_group)
      feature = FeatureDefinition.new(feature, **options)
      FeatureSet.current.add(feature)
    end

    def strategy(strategy = nil, **options, &block)
      if block_given?
        options[:name] = strategy.to_s
        options[:lambda] = block
        strategy = Strategies::LambdaStrategy
      end

      if strategy.kind_of?(Symbol)
        name = ActiveSupport::Inflector.camelize(strategy) + "Strategy"
        strategy = Strategies.const_get(name)
      end

      if strategy.kind_of?(Class)
        strategy = strategy.new(**options)
      end

      FeatureSet.current.use(strategy)
    rescue StandardError => err
      if FeatureSet.current.raise_strategy_errors
        raise err
      else
        warn "WARNING: Unable to load Flipflop strategy #{strategy}: #{err}"
      end
    end
  end
end
