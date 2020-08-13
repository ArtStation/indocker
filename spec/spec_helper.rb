require "bundler/setup"

require 'simplecov'
SimpleCov.start do
  add_filter "/example/"
end

require "indocker"
require "pry"

Dir.glob(File.join(".", "lib", '**', '*.rb')) do |file|
  require_relative File.expand_path(file)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def setup_indocker(options = {})
  require_relative '../example/indocker/bin/utils/configurations'

  Indocker.set_configuration_name(options[:configuration] || "external")
  require_relative '../example/indocker/setup'

  Indocker.set_log_level(options[:debug] ? Logger::DEBUG : Logger::INFO)
end
