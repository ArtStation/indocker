Indocker.add_build_server(
  Indocker::BuildServer.new(
    name: :local_bs,
    host: 'localhost',
    user: `whoami`.strip,
    port: 22
  )
)