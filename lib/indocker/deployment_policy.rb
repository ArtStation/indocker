class Indocker::DeploymentPolicy
  attr_reader  :deploy_containers, :deploy_tags, :servers, 
               :skip_dependent, :skip_tags, :skip_containers, :skip_build, :skip_deploy, 
               :force_restart, :skip_force_restart, :auto_confirm, :require_confirmation

  def initialize(deploy_containers:, deploy_tags:, servers:, 
                skip_dependent:, skip_tags:, skip_containers:, skip_build:, skip_deploy:, 
                force_restart:, skip_force_restart:, auto_confirm:, require_confirmation:)
    @deploy_containers = deploy_containers
    @deploy_tags = deploy_tags
    @servers = servers
    @skip_dependent = skip_dependent
    @skip_tags = skip_tags
    @skip_containers = skip_containers
    @skip_build = skip_build
    @skip_deploy = skip_deploy
    @force_restart = force_restart
    @skip_force_restart = skip_force_restart
    @auto_confirm = auto_confirm
    @require_confirmation = require_confirmation
  end
end