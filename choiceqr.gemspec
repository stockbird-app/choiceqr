require_relative "lib/choiceqr/version"

Gem::Specification.new do |s|
  s.name        = "choiceqr"
  s.version     = ChoiceQR::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stockbird Team"]
  s.email       = ["info@stockbird.app"]
  s.homepage    = "https://github.com/stockbird-app/choiceqr"
  s.summary     = "Ruby API client for ChoiceQR"
  s.description = "A Ruby gem for interacting with the ChoiceQR Open API. Handles authentication " \
                  "and provides a clean interface to the place, menu, location, order, booking, " \
                  "and feedback resources."
  s.license     = "MIT"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/stockbird-app/choiceqr/issues",
    "changelog_uri" => "https://github.com/stockbird-app/choiceqr/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/stockbird-app/choiceqr",
  }

  s.required_ruby_version = ">= 3.3.0"

  s.files = Dir["lib/**/*.rb", "LICENSE.md", "README.md"]

  s.add_dependency "faraday", "~> 2.7"
  s.add_dependency "faraday-retry", "~> 2.2"

  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rubocop", "~> 1.68"
  s.add_development_dependency "rubocop-rspec", "~> 3.2"
  s.add_development_dependency "webmock", "~> 3.23"
end
