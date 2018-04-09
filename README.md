# salt

![Status](https://img.shields.io/badge/status-WIP-yellow.svg)
![Language](https://img.shields.io/badge/language-crystal-black.svg)
[![Tag](https://img.shields.io/github/tag/icyleaf/salt.svg)](https://github.com/icyleaf/salt/blob/master/CHANGELOG.md)
[![Dependency Status](https://shards.rocks/badge/github/icyleaf/salt/status.svg)](https://shards.rocks/github/icyleaf/salt)
[![devDependency Status](https://shards.rocks/badge/github/icyleaf/salt/dev_status.svg)](https://shards.rocks/github/icyleaf/salt)
[![License](https://img.shields.io/github/license/icyleaf/salt.svg)](https://github.com/icyleaf/salt/blob/master/LICENSE)

A easy use Crystal modular webserver interface for Humans. Heavily inspired from Ruby's [rack](https://github.com/rack/rack) gem.

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

class Talk < Salt::App
  def call(env)
    [400, { "Content-Type" => "text/plain" }, ["Can I talk to salt?"]]
  end
end

class Shout < Salt::App
  def call(env)
    call_app(env)
    [status_code, headers, body.map &.upcase ]
  end
end

class Speaking < Salt::App
  def call(env)
    call_app(env)
    [200, { "Content-Type" => "text/plain" }, ["This is Slat speaking!"]]
  end
end

Salt.use Salt::Middlewares::Runtime, name: "Talk"
Salt.use Shout
Salt.use Speaking

Salt.run Talk.new

```

## Contributing

1. Fork it ( https://github.com/icyleaf/salt/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [icyleaf](https://github.com/icyleaf) - creator, maintainer


## Thanks

Icons made [Creaticca Creative Agency](https://www.flaticon.com/authors/creaticca-creative-agency) from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>
