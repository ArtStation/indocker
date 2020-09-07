require 'spec_helper'

RSpec.describe Indocker::DockerRunArgs do
  before { setup_indocker(debug: true) }

  subject { Indocker::DockerRunArgs }

  it "returns correct args" do
    container = get_container(:good_container)
     
    result = subject.get(container, Indocker.configuration, 1)

    expect(result).to include("--hostname external_good_container")
    expect(result).to include("--name external_good_container")
    expect(result).to include("--label good_container")
    expect(result).to include("--network external_app_net")
  end

  it "doesn't detach not-daemon container" do
    container = get_container(:good_container)
    result = subject.get(container, Indocker.configuration, 1)
    expect(result).to_not include("--detach")
  end

  it "detaches daemon container" do
    container = get_container(:daemon_container)
    result = subject.get(container, Indocker.configuration, 1)
    expect(result).to include("--detach")
  end
end
