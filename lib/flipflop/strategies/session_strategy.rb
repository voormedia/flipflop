module Flipflop
  module Strategies
    class SessionStrategy < AbstractStrategy
      class << self
        def default_description
          "Stores features in the user session. Applies to current user."
        end
      end

      def initialize(**options)
        @prefix = options.delete(:prefix).to_s.freeze
        super(**options)
      end

      def switchable?(feature)
        request?
      end

      def enabled?(feature)
        return unless request?
        return unless request.session.has_key?(variable_key(feature))
        request.session[variable_key(feature)] == true
      end

      def switch!(feature, enabled)
        request.session[variable_key(feature)] = enabled
      end

      def clear!(feature)
        request.session.delete(variable_key(feature))
      end

      protected

      def variable_key(feature)
        @prefix + feature.to_s
      end
    end
  end
end
