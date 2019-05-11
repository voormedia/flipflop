require 'terminal-table'

module Flipflop
  module Rake
    module SupportMethods
      def status_label(enabled)
        enabled.nil? ? '' : (enabled ? 'ON' : 'OFF')
      end

      def find_feature_by_name(name)
        features.find { |f| f.name == name } || raise("Feature :#{name} is not defined.")
      end

      def find_strategy_by_name(name)
        strategies.find { |s| s.name == name } || raise("Strategy :#{name} is not available.")
      end

      def table_header
        %w[feature description] + strategies.map(&:name)
      end

      def table_class
        Terminal::Table
      end

      def features
        Flipflop.feature_set.features
      end

      def strategies
        Flipflop.feature_set.strategies
      end

      def switch_feature!(feature_name, strategy_name, value)
        feature = find_feature_by_name(feature_name)
        strategy = find_strategy_by_name(strategy_name)

        if strategy.switchable?
          strategy.switch!(feature.key, value)
        else
          raise "The :#{strategy_name} strategy doesn't support switching."
        end
      end

      def clear_feature!(feature_name, strategy_name)
        feature = find_feature_by_name(feature_name)
        strategy = find_strategy_by_name(strategy_name)

        strategy.clear!(feature.key)
      end
    end
  end
end
