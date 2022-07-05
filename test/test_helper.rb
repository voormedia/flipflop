require "bundler/setup"
require "flipflop"

gem "minitest"
require "minitest/autorun"

require "action_controller"
require "action_controller/test_case"
require "rails/generators"

# Who is setting this to true? :o
$VERBOSE = false

def create_request
  env = Rack::MockRequest.env_for("/example")
  request = ActionDispatch::TestRequest.new(env)
  request.host = "example.com"
  request.session = ActionController::TestSession.new

  class << request
    def cookie_jar
      @cookie_jar ||= begin
        method = ActionDispatch::Cookies::CookieJar.method(:build)
        if method.arity == 2 # Rails 5.0
          method.call(self, {})
        else
          method.call(self)
        end
      end
    end
  end

  request
end

def capture_stdout
  stdout, $stdout = $stdout, StringIO.new
  yield rescue nil
  stdout, $stdout = $stdout, stdout
  stdout.string
end

def capture_stderr
  stderr, $stderr = $stderr, StringIO.new
  yield rescue nil
  stderr, $stderr = $stderr, stderr
  stderr.string
end

def reload_constant(name)
  Object.send(:remove_const, name.to_s)
  path = ActiveSupport::Dependencies.search_for_file(name.to_s.underscore).sub!(/\.rb\z/, "")
  ActiveSupport::Dependencies.loaded.delete(path)
  Object.const_get(name)
end

class TestEngineGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  def copy_engine_file
    copy_file "test_engine.rb", "lib/test_engine/test_engine.rb"
  end

  def copy_engine_features_file
    copy_file "test_engine_features.rb", "lib/test_engine/config/features.rb"
  end

  def require_engine
    environment "require 'test_engine/test_engine'"
  end
end

class TestFeaturesGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  def copy_app_features_file
    copy_file "test_app_features.rb", "config/features.rb"
  end
end

class TestLocaleGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  def copy_locale_file
    copy_file "nl.yml", "config/locales/nl.yml"
  end
end

class TestApp
  class << self
    def new(generators = [])
      name = "my_test_app"
      super(name, generators).tap do |current|
        current.create!
        current.load!
        current.migrate!
      end
    end
  end

  attr_reader :name, :generators

  def initialize(name, generators = [])
    @name = name
    @generators = generators
  end

  def create!
    require "rails/generators/rails/app/app_generator"
    require "generators/flipflop/install/install_generator"

    FileUtils.rm_rf(File.expand_path("../../" + path, __FILE__))
    Dir.chdir(File.expand_path("../..", __FILE__))

    Rails::Generators::AppGenerator.new([path],
      quiet: true,
      api: rails_api_only?,
      skip_active_job: true,
      skip_active_storage: true,
      skip_action_cable: true,
      skip_action_mailer: true,
      skip_bootsnap: true,
      skip_bundle: true,
      skip_puma: true,
      skip_gemfile: true,
      skip_git: true,
      skip_javascript: true,
      skip_keeps: true,
      skip_spring: true,
      skip_test_unit: true,
      skip_turbolinks: true,
    ).invoke_all

    if rails_api_only?
      project_root = Pathname.new(__dir__.to_s).parent
      manifest_path = project_root.join(path).join("app/assets/config/manifest.js")
      manifest_path.dirname.mkpath
      manifest_path.write(project_root.join("app/assets/config/manifest.js").read)
    end

    # Remove bootsnap if present, this interferes with reloading apps.
    boot_path = File.expand_path("../../" + path + "/config/boot.rb", __FILE__)
    File.write(boot_path, File.read(boot_path).gsub("require 'bootsnap/setup'", ""))

    Flipflop::InstallGenerator.new([],
      quiet: true,
    ).invoke_all

    generators.each do |generator|
      generator.new([], quiet: true, force: true).invoke_all
    end
  end

  def load!
    ENV["RAILS_ENV"] = "test"
    require "rails"
    require "flipflop/engine"

    ActiveSupport::Dependencies.autoload_paths = []
    ActiveSupport::Dependencies.autoload_once_paths = []
    load File.expand_path("../../#{path}/config/application.rb", __FILE__)
    Zeitwerk::Registry.loaders.each(&:unregister) if defined?(Zeitwerk)
    load File.expand_path("../../#{path}/config/environments/test.rb", __FILE__)
    Rails.application.config.cache_classes = false
    if Gem::Version.new(Rails.version) < Gem::Version.new('7')
      Rails.application.config.action_view.raise_on_missing_translations = true
    else
      Rails.application.config.i18n.raise_on_missing_translations = true
    end
    Rails.application.config.i18n.enforce_available_locales = false
    Rails.application.config.autoloader = :classic # Disable Zeitwerk in Rails 6+

    # Avoid Rails 6+ deprecation warning
    if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter) &&
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.respond_to?(:represent_boolean_as_integer=) &&
      Rails.application.config.active_record.sqlite3.nil?
      Rails.application.config.active_record.sqlite3 = ActiveSupport::OrderedOptions.new
    end

    # Avoid Rails 6+ deprecation warning
    if defined?(ActionView::Railtie::NULL_OPTION)
      Rails.application.config.action_view.finalize_compiled_template_methods = ActionView::Railtie::NULL_OPTION
    end

    Rails.application.config.active_support.remove_deprecated_time_with_zone_name = false
    Rails.application.initialize!
    Zeitwerk::Registry.loaders.each(&:unregister) if defined?(Zeitwerk)

    I18n.locale = :en

    require "capybara/rails"
  end

  def migrate!
    ActiveRecord::Base.establish_connection

    capture_stdout { ActiveRecord::Tasks::DatabaseTasks.create_current }
    ActiveRecord::Migration.verbose = false

    if defined?(ActiveRecord::Migrator.migrate)
      ActiveRecord::Migrator.migrate(Rails.application.paths["db/migrate"].to_a)
    elsif ActiveRecord::Base.connection.respond_to?(:schema_migration)
      ActiveRecord::MigrationContext.new(Rails.application.paths["db/migrate"], ActiveRecord::Base.connection.schema_migration).migrate
    else
      ActiveRecord::MigrationContext.new(Rails.application.paths["db/migrate"]).migrate
    end
  end

  def unload!
    ENV["RAILS_ENV"] = nil
    Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
    Flipflop::FeatureLoader.instance_variable_set(:@current, nil)

    match = -> (path) { path.include?(File.expand_path("../..", __FILE__)) }
    Rails.application.config.i18n.railties_load_path.reject!(&match)
    Rails.application.config.i18n.load_path.reject!(&match)
    I18n.load_path.reject!(&match)

    Rails.app_class.instance_variable_set(:@instance, nil) if defined?(Rails.app_class)
    Rails.instance_variable_set(:@application, nil)
    I18n::Railtie.instance_variable_set(:@i18n_inited, false)

    Object.send(:remove_const, name.camelize)
    Flipflop.send(:remove_const, "Feature")
  end

  private

  def rails_api_only?
    ENV["RAILS_API_ONLY"].to_i.nonzero?
  end

  def path
    "tmp/" + name
  end
end
