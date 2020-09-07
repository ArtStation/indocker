require 'spec_helper'

RSpec.describe Indocker::Launchers::ConfigurationDeployer do
  before { setup_indocker(debug: true) }

  def build_remote_operation
    thread = Thread.new() {}

    Indocker::Launchers::DTO::RemoteOperationDTO.new(thread, :external, :indocker_sync)
  end

  subject { Indocker::Launchers::ConfigurationDeployer.new(
    logger: Indocker.logger,
    global_logger: Indocker.global_logger
  ) }

  it "builds and deploys images" do
    deployment_policy = build_deployment_policy({
      containers: [:good_container]
    })

    expect(subject).to receive(:compile_image).once.and_return([build_remote_operation])
    expect(subject).to receive(:deploy_container).once.and_return([build_remote_operation])
    expect(subject).to receive(:sync_indocker).once.and_return([build_remote_operation])
    expect(subject).to receive(:sync_env_files).once.and_return([build_remote_operation])
    expect(subject).to receive(:pull_repositories).once.and_return([build_remote_operation])
    expect(subject).to receive(:sync_artifacts).once.and_return([build_remote_operation])

    subject.run(configuration: Indocker.configuration, deployment_policy: deployment_policy)
  end
end
