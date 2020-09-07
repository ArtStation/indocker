Indocker.define_env_file(
  Indocker::EnvFiles::Local.new(
    :development_env,
    File.expand_path(File.join(__dir__, '../env_files/development_env.env'))
  )
)