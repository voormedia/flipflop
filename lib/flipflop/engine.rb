module Flipflop
  class Engine < ::Rails::Engine
    attr_accessor :rake_task_executing
    class_attribute :config_file
    self.config_file = "config/features.rb"

    isolate_namespace Flipflop

    # The following middleware needs to be inserted for this engine, because it
    # may not be available in Rails API only apps.
    middleware.use Rack::MethodOverride
    middleware.use ActionDispatch::Cookies

    config.app_middleware.insert_after ActionDispatch::Callbacks,
      FeatureCache::Middleware

    config.flipflop = ActiveSupport::OrderedOptions.new

    initializer "flipflop.features_path" do |app|
      app.paths.add(config_file)
    end

    initializer "flipflop.features_reloader" do |app|
      app.reloaders.push(reloader = feature_reloader(app))
      to_prepare do
        reloader.execute
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

    def feature_reloader(app)
      features = app.paths[config_file].existent
      ActiveSupport::FileUpdateChecker.new(features) do
        features.each { |path| load(path) }
      end
    end

    def to_prepare
      klass = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
      klass.to_prepare(&Proc.new)
    end
  end
end
