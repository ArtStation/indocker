Indocker.add_server(
  Indocker::Server.new(
    name: :localhost,
    host: 'localhost',
    user: `whoami`.strip,
    port: 22
  )
)