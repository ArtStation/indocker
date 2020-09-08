Indocker.add_artifact(
  Indocker::Artifacts::Git.new(
    name:        :indocker_readme,
    remote_name: 'origin',
    remote_url:  'https://github.com/ArtStation/indocker.git',
    branch:      :master,
    files: [
      Indocker::Artifacts::DTO::FileDTO.new(
        source_path: './README.md',
        target_path: Indocker.deploy_dir,
      )
    ]
  )
)

Indocker.add_artifact(
  Indocker::Artifacts::Remote.new(
    name: :hosts_file,
    files: [
      Indocker::Artifacts::DTO::FileDTO.new(
        source_path: '/etc/hosts',
        target_path: Indocker.deploy_dir,
      )
    ]
  )
)