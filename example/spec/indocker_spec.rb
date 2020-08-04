require 'spec_helper'

RSpec.describe Indocker do
  it "has a version number" do
    expect(Indocker::VERSION).not_to be nil
  end

  it "properly handles successful build" do
    launch_deployment(configuration: "external", containers: [:ruby])
  end

  it "properly handles failed build" do
    expect{
      launch_deployment(configuration: "external", containers: [:container_failing_build])
    }.to raise(SystemExit)
  end
end
