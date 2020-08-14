require 'spec_helper'

RSpec.describe Indocker do
  before { setup_indocker(debug: true) }

  describe "successful deployment" do
    it "doesn't raise any error" do
      expect{
        Indocker.deploy(containers: [:good_container])
      }.to_not raise_error
    end

    it "shows a message about successful deploy" do
      allow(Indocker.global_logger).to receive(:info).at_least(:once)
      
      Indocker.deploy(containers: [:good_container])

      expect(Indocker.global_logger).to have_received(:info).at_least(:once).with(/Deployment finished/)
    end
  end

  describe "failed build" do
    it "exits with an error" do
      expect{
        Indocker.deploy(containers: [:bad_container_build])
      }.to raise_error(SystemExit)
    end
  end

  describe "failed start for container with no daemonize" do
    it "exits without error" do
      expect{
        Indocker.deploy(containers: [:bad_container_start])
      }.to raise_error(SystemExit)
    end
  end
end
