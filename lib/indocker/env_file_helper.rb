class Indocker::EnvFileHelper
  ENV_FILES_FOLDER = 'env_files'.freeze

  class << self
    def path(env_file)
      File.expand_path(File.join(folder, File.basename(env_file.path)))
    end

    def folder
       File.join(Indocker.deploy_dir, ENV_FILES_FOLDER)
    end
  end
end