source "https://rubygems.org"
gemspec

group :test do
  version = ENV["RAILS_VERSION"] || "master"
  if version == "master"
    gem "rails", github: "rails/rails"
    gem "arel", github: "rails/arel"
  else
    gem "rails", "~> #{version}.0"
  end

  gem "bootstrap", "= 4.0.0.alpha6", require: false

  gem "fakeredis", require: false

  if version == "master" || version >= "6"
    gem "sqlite3", "~> 1.4.0", platform: :ruby
  else
    gem "sqlite3", "~> 1.3.6", platform: :ruby
  end
  if version >= "5.2" || Gem::Version.new(RUBY_VERSION) > Gem::Version.new("2.4.4")
    gem 'sassc-rails'
  end

  if RUBY_PLATFORM == 'java'
    gem "activerecord-jdbcsqlite3-adapter", platform: :jruby,
      github: "jruby/activerecord-jdbc-adapter", tag: ENV['JRUBY_AR_JDBC_ADAPTER_VERSION']
  end

  gem "minitest", ">= 4.2"
  gem "capybara", ">= 2.6"

  if Gem::Version.new(RUBY_VERSION) > Gem::Version.new("2.2.4")
    gem "listen", ">= 3.0", require: false
  end

  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.1.0")
    # Nokogiri 1.7+ requires Ruby 2.1+.
    gem "nokogiri", "< 1.7"
  end
end
