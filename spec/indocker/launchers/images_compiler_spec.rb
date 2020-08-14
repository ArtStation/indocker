require 'spec_helper'

RSpec.describe Indocker::Launchers::ImagesCompiler do
  before { setup_indocker(debug: true) }

  subject { Indocker::Launchers::ImagesCompiler.new(
    Indocker.logger
  ) }

  it "builds images" do    
    expect(Indocker::Docker).to receive(:build).once.and_return(
      Indocker::Shell::ShellResult.new("", 0)
    )
    expect(Indocker::Docker).to receive(:tag).once.and_return(
      Indocker::Shell::ShellResult.new("", 0)
    )

    subject.compile(configuration: Indocker.configuration, image_list: [:good_container], skip_dependent: false)
  end
end
