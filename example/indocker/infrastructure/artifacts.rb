Indocker.add_artifact(
  Indocker::Artifacts::Git.new(
    name:        :indocker_readme,
    remote_name: 'origin',
    remote_url:  'https://github.com/ArtStation/indocker.git',
    branch:      :master,
    files: [
      Indocker::Artifacts::DTO::FilesDTO.new(
        source_path: './README.md',
        target_path: Indocker.deploy_dir,
      )
    ]
  )
)

Indocker.add_artifact(
  Indocker::Artifacts::Remote.new(
    name:        :indocker_readme,
    files: [
      Indocker::Artifacts::DTO::FilesDTO.new(
        source_path: '/home/indocker/.bash_profile',
        target_path: Indocker.deploy_dir,
      )
    ]
  )
)