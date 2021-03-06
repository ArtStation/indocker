# InDocker

[![Codeship Status for ArtStation/indocker](https://app.codeship.com/projects/bf8888c0-b7e4-0138-fc1f-7e2faa53772a/status?branch=master)](https://app.codeship.com/projects/404716)

Docker Containers Deployment

## Installation

```
$ gem install indocker
```

## Development: Launch example app locally

```ruby
cd example
indocker/bin/deploy -C dev -c ruby -d
```

## Development: Launch example with external host

NOTE: Default external host requires extra permissions.

```ruby
cd example
indocker/bin/deploy -C external -c ruby -d
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
