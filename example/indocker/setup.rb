require 'indocker'

root_dir = File.join(__dir__, '..', '..')

Indocker.set_root_dir(__dir__)
Indocker.set_deploy_dir(File.join(root_dir, 'tmp', 'deployment'))

Indocker.set_dockerignore [
  'Dockerfile',
  '.DS_Store',
  '**/.DS_Store',
  '**/*.log',
  '.vscode',
  'tmp',
]

require_relative 'infrastructure/registries'
require_relative 'infrastructure/servers'
require_relative 'infrastructure/build_servers'
require_relative 'infrastructure/networks'

Indocker.set_bounded_contexts_dir(File.join(__dir__, 'bounded_contexts'))

require_relative "configurations/#{Indocker.configuration_name}"