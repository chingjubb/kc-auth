require "bundler/setup"
require "kc/auth"
require "timecop"
require "rack/mock"
require_relative "./support/public_key_resolver_stub"
require_relative "./support/requests_stub"
require_relative "./support/key_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
