require "bundler/setup"
require "indocker"
require "pry"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def launch_deployment(options = {})
  require_relative '../indocker/bin/utils/configurations'

  Indocker.set_configuration_name(options[:configuration])
  require_relative '../indocker/setup'

  Indocker.set_log_level(Logger::DEBUG)

  Indocker.deploy(
    containers:           options[:containers] || [],
    tags:                 options[:tags] || [],
    skip_containers:      options[:skip_containers] || [],
    skip_dependent:       !!options[:skip_dependent],
    servers:              options[:servers] || [],
    skip_build:           options[:skip_build],
    skip_deploy:          options[:skip_deploy],
    force_restart:        options[:force_restart],
    skip_tags:            options[:skip_tags] || [],
    skip_force_restart:   options[:skip_force_restart] || [],
    auto_confirm:         !!options[:auto_confirm],
    require_confirmation: !!options[:require_confirmation],
  )
end
