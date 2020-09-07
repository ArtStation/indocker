require 'spec_helper'

RSpec.describe Indocker::Launchers::ContainerRunner do
  before { setup_indocker(debug: true) }

  subject { Indocker::Launchers::ContainerRunner.new(
    Indocker.logger
  ) }

  it "runs containers" do    
    expect(Indocker::Docker).to receive(:run).once

    subject.run(configuration: Indocker.configuration, container_name: :good_container, force_restart: true)
  end
end
