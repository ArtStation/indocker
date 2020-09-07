Indocker.add_artifact(
  Indocker::Artifacts::Git.new(
    name:        :indocker_readme,
    remote_name: 'origin',
    remote_url:  'https://github.com/ArtStation/indocker.git',
    branch:      :master,
    source_path: './README.md',
    target_path: File.join(Indocker.deploy_dir, 'README.md'),
  )
)