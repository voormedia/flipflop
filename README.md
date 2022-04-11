[<img src="https://travis-ci.org/voormedia/flipflop.svg?branch=master" alt="Build Status">](https://travis-ci.org/voormedia/flipflop)

# Flipflop your features

**Flipflop** provides a declarative, layered way of enabling and disabling
application functionality at run-time. It is originally based on
[Flip](https://github.com/pda/flip). **Flipflop** has the following features:
* simple configuration
* ease of use for developers
* an improved dashboard
* manage features via console (using rake tasks)
* thread safety
* better database performance due to per-request caching, enabled by default
* more strategies (Sequel, Redis, query strings, sessions, custom code)
* more strategy options (cookie options, strategy names and descriptions, custom database models)
* the ability to use the same strategy twice, with different options
* configuration in a fixed location (`config/features.rb`) that is usable even if you don't use the database strategy
* dashboard is inaccessible in production by default, for safety in case of misconfiguration
* removes controller filters and view helpers, to promote uniform semantics to check for features (facilitates project-wide searching)
* support for API only Rails apps
* support for loading features from Rails engines
* support for feature groups

You can configure strategy layers that will evaluate if a feature is currently
enabled or disabled. Available strategies are:
* a per-feature default setting
* database (with Active Record, Sequel, or Redis), to flipflop features site-wide for all users
* cookie or session, to flipflop features for single users
* query string parameters, to flipflop features occasionally (in development mode for example)
* custom strategy code

Flipflop has a dashboard interface that's easy to understand and use.

[<img src="https://raw.githubusercontent.com/voormedia/flipflop/screenshots/dashboard.png" alt="Dashboard">](https://raw.githubusercontent.com/voormedia/flipflop/screenshots/dashboard.png)

If you prefer, you can use the included rake tasks to enable or disable features.

```
rake flipflop:features                    # Shows features table
rake flipflop:turn_on[feature,strategy]   # Enables a feature with the specified strategy
rake flipflop:turn_off[feature,strategy]  # Disables a feature with the specified strategy
rake flipflop:clear[feature,strategy]     # Clears a feature with the specified strategy
```

## Rails requirements

This gem requires Rails 4, 5 or 6. Using an ORM layer is entirely optional.

## Installation

Add the gem to your `Gemfile`:

```ruby
gem "flipflop"
```

Generate routes, feature settings and database migration:

```
rails g flipflop:install
```

Run the migration to store feature settings in your database:

```
rake db:migrate
```

## Declaring features

Features and strategies are declared in `config/features.rb`:

```ruby
Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record # or :sequel, :redis
  strategy :default

  # Basic feature declaration:
  feature :shiny_things

  # Enable features by default:
  feature :world_domination, default: true

  # Group features together:
  group :improved_design do
    feature :improved_navigation
    feature :improved_homepage
  end
end
```

This file is automatically reloaded in development mode. No need to restart
your server after making changes.

Feature definitions support these options:
* `:default` – The feature's default value. This is the value of the feature if no strategy configures an explicit value. Defaults to `false`.
* `:description` – An optional description of the feature. Displayed on the dashboard if present.
* `:title` – An optional title of the feature. This defaults to a humanized version of the feature name. Displayed on the dashboard.

## Strategies

The following strategies are provided:
* `:active_record`/`:sequel` – Save feature settings in the database.
    * `:class` – Provide the feature model. `Flipflop::Feature` by default (which is defined automatically and uses the table `flipflop_features`). The `ActiveRecord` version honors `default_scope` when features are resolved or switched on/off.
* `:cookie` – Save feature settings in browser cookies for the current user.
    * `:prefix` – String prefix for all cookie names. Defaults to no prefix.
    * `:path` – The path for which the cookies apply. Defaults to the root of the application.
    * `:domain` – Cookie domain. Is `nil` by default (no specific domain). Can be `:all` to use the topmost domain. Can be an array of domains.
    * `:secure` – Only set cookies if the connection is secured with TLS. Default is `false`.
    * `:httponly` – Whether the cookies are accessible via scripting or only HTTP. Default is `false`.
* `:query_string` – Interpret query string parameters as features. This strategy is only used for resolving. It does not allow switching features on/off.
    * `:prefix` – String prefix for all query string parameters. Defaults to no prefix.
* `:redis` – Save feature settings in Redis.
    * `:client` – Use the specified Redis client instead of `Redis.new`.
    * `:prefix` – String prefix for all Redis keys. Defaults to no prefix.
* `:session` – Save feature settings in the current user's application session.
    * `:prefix` – String prefix for all session variables. Defaults to no prefix.
* `:default` – Not strictly needed, all feature defaults will be applied if no strategies match a feature. Include this strategy to determine the order of using the default value, and to make it appear in the dashboard.
* `:test` – Simple strategy that stores features in memory. Useful for testing. If you call `Flipflop::FeatureSet.current.test!` this strategy is enabled and replaces all configured strategies.

All strategies support these options, to change the appearance of the dashboard:
* `:name` – The name of the strategy. Defaults to the name of the selected strategy.
* `:description` – The description of the strategy. Every strategy has a default description.
* `:hidden` – Optionally hides the strategy from the dashboard. Default is `false`.

The same strategy type can be used multiple times, as long as the options are
different. To prevent subtle bugs, an error is raised if two identical
strategies are configured.

## Checking if a feature is enabled

`Flipflop.enabled?` or the dynamic predicate methods can be used to check
feature state:

```ruby
Flipflop.enabled?(:world_domination)  # true
Flipflop.world_domination?            # true

Flipflop.enabled?(:shiny_things)      # false
Flipflop.shiny_things?                # false
```

This works everywhere. In your views:

```erb
<div>
  <% if Flipflop.world_domination? %>
    <%= link_to "Dominate World", world_dominations_path %>
  <% end %>
</div>
```

In your controllers:

```ruby
class ShinyThingsController < ApplicationController
  def index
    return head :forbidden unless Flipflop.shiny_things?
    # Proceed with shiny things...
  end
end
```

In your models:

```ruby
class ShinyThing < ActiveRecord::Base
  after_initialize do
    if !Flipflop.shiny_things?
      raise ActiveRecord::RecordNotFound
    end
  end
end
```

## Custom strategies

Custom light-weight strategies can be defined with a block:

```ruby
Flipflop.configure do
  strategy :random do |feature|
    rand(2).zero?
  end
  # ...
end
```

You can define your own custom strategies by inheriting from
`Flipflop::Strategies::AbstractStrategy`:

```ruby
class UserPreferenceStrategy < Flipflop::Strategies::AbstractStrategy
  class << self
    def default_description
      "Allows configuration of features per user."
    end
  end

  def switchable?
    # Can only switch features on/off if we have the user's session.
    # The `request` method is provided by AbstractStrategy.
    request?
  end

  def enabled?(feature)
    # Can only check features if we have the user's session.
    return unless request?
    find_current_user.enabled_features[feature]
  end

  def switch!(feature, enabled)
    user = find_current_user
    user.enabled_features[feature] = enabled
    user.save!
  end

  def clear!(feature)
    user = find_current_user
    user.enabled_features.delete(feature)
    user.save!
  end

  private

  def find_current_user
    # The `request` method is provided by AbstractStrategy.
    User.find_by_id(request.session[:user_id])
  end
end
```

Use it in `config/features.rb`:

```ruby
Flipflop.configure do
  strategy UserPreferenceStrategy # name: "my strategy", description: "..."
end
```

If you define your class inside `Flipflop::Strategies`, you can use the
shorthand name to refer to your strategy:

```ruby
module Flipflop::Strategies
  class UserPreferenceStrategy < AbstractStrategy
    # ...
  end
end
```

```ruby
Flipflop.configure do
  strategy :user_preference
end
```

## Dashboard access control

The dashboard provides visibility and control over the features.

You don't want the dashboard to be public. For that reason it is only available
in the development and test environments by default. Here's one way of
implementing access control.

In `app/config/application.rb`:

```ruby
config.flipflop.dashboard_access_filter = :require_authenticated_user
```

In `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  def require_authenticated_user
    head :forbidden unless User.logged_in?
  end
end
```

Or directly in `app/config/application.rb`:

```ruby
config.flipflop.dashboard_access_filter = -> {
  head :forbidden unless User.logged_in?
}
```

## Features in Rails engines

You can use features in Rails engines. Simply tell Flipflop to load files from
an additional file in an initializer. You can define features and strategies.
Both will be merged with application features. You'll have to somewhat careful
with defining strategies in the engine to avoid conflicts.

```ruby
class MyEngine < Rails::Engine
  initializer "load_features" do
    # Features from config/features.rb in your engine are merged with
    # any application features.
    Flipflop::FeatureLoader.current.append(self)
  end
end
```

## Internationalization

The dashboard is translatable. Make sure `I18n.locale` is set to the correct
value in your `ApplicationController` or alternatively in
`dashboard_access_filter`.

Take a look at [the English translations](config/locales/en.yml) to see which
keys should be present and translated in your locale file.

## Testing

In your test environment, you typically want to keep your features. But to make
testing easier, you may not want to use any of the strategies you use in
development and production. You can replace all strategies with a single
`:test` strategy by calling `Flipflop::FeatureSet.current.test!`. The test
strategy will be returned. You can use this strategy to enable and disable
features.

```ruby
describe WorldDomination do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:world_domination, true)
  end

  it "should dominate the world" do
     # ...
  end
end
```

If you are not happy with the default test strategy (which is essentially a
simple thread-safe hash object), you can provide your own implementation as
argument to the `test!` method.

## License

This software is licensed under the MIT License. [View the license](LICENSE).
