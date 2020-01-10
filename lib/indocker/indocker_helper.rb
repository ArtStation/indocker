class Indocker::IndockerHelper
  INDOCKER_FOLDER = 'indocker'.freeze

  class << self
    def indocker_dir
      File.join(Indocker.deploy_dir, INDOCKER_FOLDER)
    end
  end
end