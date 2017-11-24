# salt

> **atention**: This is a early-stage project.

a modular Crystal webserver interface.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  salt:
    github: icyleaf/salt
```

## Usage

```crystal
require "salt"

class Talk < Salt::App
  def call(context)
    [400, { "Content-Type" => "text/plain" }, ["Can I talk to salt?"]]
  end
end

class Shout < Salt::App
  def call(context)
    call_app(context)
    [status_code, headers, body.map &.upcase ]
  end
end

class Speaking < Salt::App
  def call(context)
    call_app(context)
    [200, { "Content-Type" => "text/plain" }, ["This is Slat speaking!"]]
  end
end

Salt.use Salt::Middlewares::Runtime, "Talk"
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
