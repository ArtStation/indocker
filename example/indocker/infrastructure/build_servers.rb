Indocker.add_build_server(
  Indocker::BuildServer.new(
    name: :local_bs,
    host: 'localhost',
    user: `whoami`.strip,
    port: 22
  )
)

external_host = ENV['INDOCKER_EXTERNAL_HOST'] || 'indocker-test.artstationstaging.com'
external_user = ENV['INDOCKER_EXTERNAL_USER'] || 'indocker'
Indocker.add_build_server(
  Indocker::BuildServer.new(
    name: :external_bs,
    host: external_host,
    user: external_user,
    port: 22
  )
)