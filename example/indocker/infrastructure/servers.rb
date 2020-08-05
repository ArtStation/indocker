Indocker.add_server(
  Indocker::Server.new(
    name: :localhost,
    host: 'localhost',
    user: `whoami`.strip,
    port: 22
  )
)

external_host = ENV['INDOCKER_EXTERNAL_HOST'] || 'indocker.artstn.ninja'
external_user = ENV['INDOCKER_EXTERNAL_USER'] || 'indocker'
Indocker.add_server(
  Indocker::Server.new(
    name: :external,
    host: external_host,
    user: external_user,
    port: 22
  )
)