require 'spec_helper'

RSpec.describe Indocker::Launchers::ImagesCompiler do
  before { setup_indocker(debug: true) }

  subject { Indocker::Launchers::ImagesCompiler.new(
    Indocker.logger
  ) }

  it "builds images" do    
    expect(Indocker::Docker).to receive(:build).with("dev/parent_image_image:latest", "").once.and_return(
      Indocker::Shell::ShellResult.new("", 0)
    )
    expect(Indocker::Docker).to receive(:build).with("dev/good_container_image:latest", "").once.and_return(
      Indocker::Shell::ShellResult.new("", 0)
    )
    expect(Indocker::Docker).to receive(:tag).with("dev/parent_image_image:latest", "dev/parent_image_image:latest").once.and_return(
      Indocker::Shell::ShellResult.new("", 0)
    )
    expect(Indocker::Docker).to receive(:tag).with("dev/good_container_image:latest", "dev/good_container_image:latest").once.and_return(
      Indocker::Shell::ShellResult.new("", 0)
    )

    subject.compile(configuration: Indocker.configuration, image_list: [:good_container], skip_dependent: false)
  end
end
