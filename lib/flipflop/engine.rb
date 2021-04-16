module Flipflop
  class Engine < ::Rails::Engine
    attr_accessor :rake_task_executing

    isolate_namespace Flipflop

    # The following middleware needs to be inserted for this engine, because it
    # may not be available in Rails API only apps.
    middleware.use Rack::MethodOverride
    middleware.use ActionDispatch::Cookies

    config.app_middleware.insert_after ActionDispatch::Callbacks,
      FeatureCache::Middleware

    config.flipflop = ActiveSupport::OrderedOptions.new

    initializer "flipflop.config" do |app|
      raise_errors = config.flipflop.raise_strategy_errors
      raise_errors = (ENV["RACK_ENV"] || ENV["RAILS_ENV"]) != "test" if raise_errors.nil?
      FeatureSet.current.raise_strategy_errors = raise_errors
    end

    initializer "flipflop.features_path" do |app|
      FeatureLoader.current.append(app)
    end

    initializer "flipflop.features_loader" do |app|
      app.reloaders.push(FeatureLoader.current)
      to_prepare do
        FeatureLoader.current.execute
      end
    end

    initializer "flipflop.dashboard", after: "flipflop.features_reloader" do |app|
      next if rake_task_executing
      if actions = config.flipflop.dashboard_access_filter
        to_prepare do
          Flipflop::FeaturesController.before_action(*actions)
          Flipflop::StrategiesController.before_action(*actions)
        end
      end
    end

    initializer "flipflop.request_interceptor" do |app|
      interceptor = Strategies::AbstractStrategy::RequestInterceptor
      ActionController::Base.send(:include, interceptor)
      ActionController::API.send(:include, interceptor) if defined?(ActionController::API)
    end

    def run_tasks_blocks(app)
      # Skip initialization if we're in a rake task.
      self.rake_task_executing = true
      super
    end

    private

    def to_prepare(&block)
      klass = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
      klass.to_prepare(&block)
    end
  end
end
