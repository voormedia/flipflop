module Flipflop
  module Strategies
    class AbstractStrategy
      module RequestInterceptor
        class << self
          def request
            Thread.current.thread_variable_get(:flipflop_request)
          end

          def request=(request)
            Thread.current.thread_variable_set(:flipflop_request, request)
          end
        end

        extend ActiveSupport::Concern

        included do
          before_action do
            RequestInterceptor.request = request
          end

          after_action do
            RequestInterceptor.request = nil
          end
        end
      end

      class << self
        def default_name
          return "anonymous" unless name
          name.split("::").last.gsub(/Strategy$/, "").underscore
        end

        def default_description
        end
      end

      attr_reader :key, :name, :title, :description

      def initialize(**options)
        # Generate key before setting instance that should be excluded from
        # unique key generation.
        @key = OptionsHasher.new(self).generate

        @name = (options.delete(:name) || self.class.default_name).freeze
        @title = @name.humanize.freeze
        @description = (options.delete(:description) || self.class.default_description).freeze
        @hidden = !!options.delete(:hidden) || false

        if options.any?
          raise StrategyError.new(name, "did not understand option #{options.keys.map(&:inspect) * ', '}")
        end
      end

      def hidden?
        @hidden
      end

      # Return true iff this strategy is able to switch features on/off.
      # Return false otherwise.
      def switchable?(feature)
        false
      end

      # Return true iff the given feature symbol is explicitly enabled.
      # Return false iff the given feature symbol is explicitly disabled.
      # Return nil iff the given feature symbol is unknown by this strategy.
      def enabled?(feature)
        raise NotImplementedError
      end

      # Enable/disable (true/false) the given feature symbol explicitly.
      def switch!(feature, enabled)
        raise NotImplementedError
      end

      # Remove the feature symbol from this strategy. It should no longer be
      # recognized afterwards: enabled?(feature) will return nil.
      def clear!(feature)
        raise NotImplementedError
      end

      # Optional. Remove all features, so that no feature is known.
      def reset!
        raise NotImplementedError
      end

      protected

      # Returns the request. Raises if no request is available, for example if
      # the strategy was used outside of a request context.
      def request
        RequestInterceptor.request or
          raise StrategyError.new(name, "required request, but was used outside request context")
      end

      # Returns true iff a request is available.
      def request?
        !RequestInterceptor.request.nil?
      end
    end
  end
end
