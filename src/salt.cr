require "./salt/*"

module Salt
  # Run http server and takes an argument that is an Salt::App that responds to #call
  #
  # ```
  # class Foo < Salt::App
  #   def call(env)
  #     [200, {"Content-Type" => "text/plain"}, ["hello world"]]
  #   end
  # end
  #
  # Salt.run Foo.new
  # ```
  def self.run(app : Salt::App, **options)
    Salt::Server.new(**options).run(app)
  end

  # Specifies middleware to use in a stack.
  #
  # ```
  # class Foo < Salt::App
  #   def call(env)
  #     call_app(env)
  #     [200, {"Content-Type" => "text/html"}, ["<h1>", "Hello Salt", "</h1>"]]
  #   end
  # end
  #
  # Salt.use Salt::Middlewares::Runtime, name: "Crystal"
  #
  # Sale.run Foo
  # ```
  def self.use(middleware, **options)
    Salt::Middlewares.use(middleware, **options)
  end

  # Set alias of middlewares

  alias Runtime = Middlewares::Runtime
  alias Logger = Middlewares::Logger
  alias CommonLogger = Middlewares::CommonLogger
  alias ShowExceptions = Middlewares::ShowExceptions
  alias Session = Middlewares::Session
  alias Head = Middlewares::Head
  alias File = Middlewares::File
  alias Directory = Middlewares::Directory

  # Set alias of environment of server

  {% for name in Server::Environment.constants %}
    {{ name.id }} = Server::Environment::{{ name.id }}.value
  {% end %}
end
