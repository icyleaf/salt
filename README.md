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
- [x] `Static`
- [ ] `SendFile`
- [x] `ETag`
- [x] `BasicAuth`
- [x] `Router` (lightweight)

All these components use the same interface, which is described in detail in the Salt::App specification. These optional components can be used in any way you wish.

## How to Contribute

Your contributions are always welcome! Please submit a pull request or create an issue to add a new question, bug or feature to the list.

All [Contributors](https://github.com/icyleaf/salt/graphs/contributors) are on the wall.

## You may also like

- [halite](https://github.com/icyleaf/halite) - HTTP Requests Client with a chainable REST API, built-in sessions and loggers.
- [totem](https://github.com/icyleaf/totem) - Load and parse a configuration file or string in JSON, YAML, dotenv formats.
- [markd](https://github.com/icyleaf/markd) - Yet another markdown parser built for speed, Compliant to CommonMark specification.
- [poncho](https://github.com/icyleaf/poncho) - A .env parser/loader improved for performance.
- [popcorn](https://github.com/icyleaf/popcorn) - Easy and Safe casting from one type to another.
- [fast-crystal](https://github.com/icyleaf/fast-crystal) - 💨 Writing Fast Crystal 😍 -- Collect Common Crystal idioms.

## Resouces

Heavily inspired from Ruby's <a href="https://github.com/rack/rack">rack</a> gem.

## License

[MIT License](https://github.com/icyleaf/salt/blob/master/LICENSE) © icyleaf
