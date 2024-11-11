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
      FeatureSet.current.facade.respond_to?(method, include_private) || super
    end

    def method_missing(method, *args)
      FeatureSet.current.facade.send(method, *args)
    end
  end
end
