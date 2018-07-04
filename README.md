<p align="center">
  <img alt="salt icon" src="./icon.svg" width="240" height="240" />
</p>

<p align="center">
  A Human Friendly Interface for HTTP webservers written in Crystal.
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
require "salt"
require "salt/middlewares/session/cookie"
require "salt/middlewares/logger"

class Talk < Salt::App
  def call(env)
    env.session.set("username", "icyleaf")
    env.logger.info("Start Talking!")
    {400, { "Content-Type" => "text/plain" }, ["Can I talk to salt?"]}
  end
end

class Shout < Salt::App
  def call(env)
    call_app(env)

    env.logger.debug("Shout class")
    {status_code, headers, body.map &.upcase }
  end
end

class Speaking < Salt::App
  def call(env)
    call_app(env)

    env.logger.debug("Speaking class")
    {200, headers, ["This is Slat speaking! #{env.session.get("username")}"]}
  end
end

Salt.use Salt::Session::Cookie, secret: "<change me>"
Salt.use Salt::Logger, level: Logger::DEBUG, progname: "app"
Salt.use Shout
Salt.use Speaking

Salt.run Talk.new
```

## Available middleware

- [x] `ShowExceptions`
- [x] `CommonLogger`
- [x] `Logger`
- [x] `Runtime`
- [x] `Session` (Cookie/Redis)
- [x] `Head`
- [x] `File`
- [x] `Directory`
- [ ] `Static`
- [ ] `SendFile`
- [x] `ETag`
- [x] `BasicAuth`
- [x] `Router` (lightweight)

All these components use the same interface, which is described in detail in the Salt::App specification. These optional components can be used in any way you wish.

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
