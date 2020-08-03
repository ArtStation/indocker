require 'spec_helper'

RSpec.describe Indocker do
  it "has a version number" do
    expect(Indocker::VERSION).not_to be nil
  end

  it "deploys container to an external server" do
    launch_deployment(configuration: "external", containers: [:ruby])
  end
end
