require 'spec_helper'

RSpec.describe Indocker do
  it "has a version number" do
    expect(Indocker::VERSION).not_to be nil
  end

  describe "successful deployment" do
    it "doesn't raise any error" do
      expect{
        launch_deployment(containers: [:ruby])
      }.to_not raise_error
    end

    it "shows a message about successful deploy" do
      allow(Indocker.global_logger).to receive(:info).at_least(:once)
      
      launch_deployment(containers: [:ruby])

      expect(Indocker.global_logger).to have_received(:info).at_least(:once).with(/Deployment finished/)
    end
  end

  describe "failed build" do
    it "exits with an error" do
      expect{
        launch_deployment(containers: [:container_failing_build])
      }.to raise_error(SystemExit)
    end
  end
end
