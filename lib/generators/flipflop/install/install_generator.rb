require "generators/flipflop/features/features_generator"
require "generators/flipflop/migration/migration_generator"
require "generators/flipflop/routes/routes_generator"

class Flipflop::InstallGenerator < Rails::Generators::Base
  def invoke_generators
    Flipflop::FeaturesGenerator.new([], options).invoke_all
    Flipflop::MigrationGenerator.new([], options).invoke_all
    Flipflop::RoutesGenerator.new([], options).invoke_all
  end

  def configure_dashboard
    app = tmpl("-> { head :forbidden }")
    env_dev_test = tmpl("nil")

    environment(indent(app + "\n", 4).lstrip)
    environment(indent(env_dev_test + "\n", 2).lstrip, env: [:development, :test])
  end

  private

  def tmpl(access_filter)
    return <<-RUBY
# Before filter for Flipflop dashboard. Replace with a lambda or method name
# defined in ApplicationController to implement access control.
config.flipflop.dashboard_access_filter = #{access_filter}

# By default, when set to `nil`, strategy loading errors are suppressed in test
# mode. Set to `true` to always raise errors, or `false` to always warn.
config.flipflop.raise_strategy_errors = nil
RUBY
  end

  def indent(content, multiplier = 2)
    # Don't fix indentation if Rails already does this (5.2+).
    return content if respond_to?(:optimize_indentation, true)

    spaces = " " * multiplier
    content.each_line.map {|line| line.blank? ? line : "#{spaces}#{line}" }.join
  end
end
