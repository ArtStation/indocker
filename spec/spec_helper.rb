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
  Indocker.set_log_level(options[:debug] ? Logger::DEBUG : Logger::INFO)
  require_relative '../example/indocker/bin/utils/configurations'

  Indocker.set_configuration_name(options[:configuration] || "external")
  require_relative '../example/indocker/setup'
end

def build_deployment_policy(options = {})
  Indocker::DeploymentPolicy.new(
    deploy_containers:    options[:containers] || [],
    deploy_tags:          options[:tags] || [],
    servers:              options[:servers] || [],
    skip_dependent:       options[:skip_dependent] || false,
    skip_containers:      options[:skip_containers] || [],
    skip_build:           options[:skip_build] || false,
    skip_deploy:          options[:skip_deploy] || false,
    skip_tags:            options[:skip_tags] || [],
    force_restart:        options[:force_restart] || false,
    skip_force_restart:   options[:skip_force_restart] || false,
    auto_confirm:         options[:auto_confirm] || false,
    require_confirmation: options[:require_confirmation] || false,
  )
end

def get_container(container_name)
  Indocker.configuration.containers.detect { |c| c.name == container_name }
end