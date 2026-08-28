require "webmock/rspec"
require "choiceqr"

# Top-level constants — accessible from all spec files
TOKEN     = "test_token".freeze
API_BASE  = "https://open-api.choiceqr.com".freeze

module SpecHelpers
  def build_client(**)
    ChoiceQR::Client.new(token: TOKEN, **)
  end

  def json(hash)
    JSON.generate(hash)
  end

  def api_headers
    { "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  config.warnings = true

  config.include SpecHelpers

  config.after { ChoiceQR.reset! }
end
