require 'spec_helper'

RSpec.describe Indocker do
  before { setup_indocker(debug: true) }

  it "returns the list of invalid and missing containers" do    
    result = Indocker.check(servers: [:external])
    expect(result[:missing_containers]).to include("external_bad_container_start")
  end
end
