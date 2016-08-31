# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flipflop/version"

Gem::Specification.new do |s|
  s.name        = "flipflop"
  s.version     = Flipflop::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paul Annesley", "Rolf Timmermans", "Jippe Holwerda"]
  s.email       = ["paul@annesley.cc", "rolftimmermans@voormedia.com", "jippeholwerda@voormedia.com"]
  s.homepage    = "https://github.com/voormedia/flipflop"
  s.summary     = %q{A feature flipflopper for Rails web applications.}
  s.description = %q{Declarative API for specifying features, switchable in declaration, database and cookies.}
  s.license  = "MIT"

  s.add_dependency("activesupport", ">= 4.0")
if ENV["CONTINUOUS_INTEGRATION"]
  s.files         = `git ls-files`.split("\n") + ['app/assets/stylesheets/flipflop.css']
else
  s.add_dependency("bootstrap", "= 4.0.0.alpha3")
  s.files         = `git ls-files`.split("\n")
end
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
