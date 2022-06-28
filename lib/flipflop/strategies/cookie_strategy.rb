module Flipflop
  module Strategies
    class CookieStrategy < AbstractStrategy
      class << self
        def default_description
          "Stores features in a browser cookie. Applies to current user."
        end
      end

      def initialize(**options)
        # TODO: Support :expires as a runtime-evaluated option?
        @options = options.extract!(:path, :domain, :secure, :httponly).freeze
        @prefix = options.delete(:prefix).to_s.freeze
        super(**options)
      end

      def switchable?
        request?
      end

      def enabled?(feature)
        return unless request?
        return unless request.cookie_jar.has_key?(cookie_key(feature))
        cookie = request.cookie_jar[cookie_key(feature)]
        cookie_value = cookie.is_a?(Hash) ? cookie["value"] : cookie
        cookie_value === "1"
      end

      def switch!(feature, enabled)
        value = @options.merge(value: enabled ? "1" : "0")
        request.cookie_jar[cookie_key(feature)] = value
      end

      def clear!(feature)
        options = @options.dup
        request.cookie_jar.delete(cookie_key(feature), **options)
      end

      protected

      def cookie_key(feature)
        @prefix + feature.to_s
      end
    end
  end
end
