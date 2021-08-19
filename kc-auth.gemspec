require_relative "lib/kc/common/version"

Gem::Specification.new do |spec|
  spec.name          = "kc-auth"
  spec.version       = Kc::Common::VERSION
  spec.authors       = ["Varun Agarwal"]
  spec.email         = ["varun@xfers.com"]

  spec.summary       = "Module to handle service level authentication between xfer's core services"
  spec.description   = ""
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir["README.md", "Rakefile", "lib/**/*", "bin/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty"
  spec.add_dependency "jwt", ">=2.2.0"
  spec.add_dependency "mock_redis"
  spec.add_dependency "rack", ">= 2.0"
  spec.add_dependency "rails", ">= 4.2"
  spec.add_dependency "rake"
  spec.add_dependency "redis"

  spec.add_development_dependency "byebug", "9.1.0"
  spec.add_development_dependency "rspec", "3.7.0"
  spec.add_development_dependency "timecop", "0.9.1"
  spec.add_development_dependency "webmock", "3.12.1"
end
