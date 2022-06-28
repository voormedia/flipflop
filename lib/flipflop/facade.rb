require "forwardable"

module Flipflop
  module Facade
    extend Forwardable
    delegate [:configure, :enabled?] => :feature_set
    alias_method :on?, :enabled?

    def feature_set
      FeatureSet.current
    end

    def respond_to_missing?(method, include_private = false)
      return false if method == :use_relative_model_naming?

      method[-1] == "?"
    end

    def method_missing(method, *args)
      if method[-1] == "?"
        FeatureSet.current.enabled?(method[0..-2].to_sym)
      else
        super
      end
    end
  end
end
