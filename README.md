<p align="center">
  <a href="https://github.com/icyleaf/salt">
    <img alt="salt icon" src="./icon.svg" width="240" height="240" />
  </a>
</p>

<p align="center">
  salt
  <br />
  A easy use Crystal modular webserver interface for Humans.
</p>

<p align="center">
  <img alt="Project Status" src="https://img.shields.io/badge/status-WIP-yellow.svg">
  <a href="https://crystal-lang.org/"><img alt="Langugea" src="https://img.shields.io/badge/language-crystal-776791.svg"></a>
  <a href="https://github.com/icyleaf/salt/blob/master/LICENSE"><img alt="License" src="https://img.shields.io/github/license/icyleaf/salt.svg"></a>
</p>

<p align="center">
  "Salt" icon by Creative Stall from <a href="https://thenounproject.com">Noun Project</a>.
</p>

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  salt:
    github: icyleaf/salt
    branch: master
```

## Usage

```crystal
class Talk < Salt::App
  def call(env)
    env.session.set("username", "icyleaf")

    env.logger.info("Start Talking!")
    [400, { "Content-Type" => "text/plain" }, ["Can I talk to salt?"]]
  end
end

class Shout < Salt::App
  def call(env)
    call_app(env)

    env.logger.debug("Shout class")
    [status_code, headers, body.map &.upcase ]
  end
end

class Speaking < Salt::App
  def call(env)
    call_app(env)

    env.logger.debug("Speaking class")
    [200, { "Content-Type" => "text/plain" }, ["This is Slat speaking! #{env.session.get("username")}"]]
  end
end

Salt.use Salt::Session::Cookie, secret: "<change me>"
Salt.use Salt::Logger, level: Logger::DEBUG, progname: "app"
Salt.use Shout
Salt.use Speaking

Salt.run Talk.new
```

## TODO

- [x] Web Server
  - [x] request query params
  - [x] request params in body
  - [x] request files
  - [x] get/set cookie
- [ ] Middlewares
  - [x] ShowExceptions
  - [x] CommonLogger
  - [x] Logger
  - [x] Runtime
  - [x] Session(Cookie/Redis)
  - [x] Head
  - [x] File
  - [x] Directory
  - [ ] Static
  - [ ] SendFile
  - [ ] ETag
  - [ ] Rails Flash (maybe)

## Contributing

1. Fork it ( https://github.com/icyleaf/salt/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [icyleaf](https://github.com/icyleaf) - creator, maintainer

## Resouces

Heavily inspired from Ruby's <a href="https://github.com/rack/rack">rack</a> gem.
