require "./salt/*"

module Salt
  # Run http server and takes an argument that is an Salt::App that responds to #call
  #
  # ```
  # class App < Salt::App
  #   def call(env)
  #     {200, {"Content-Type" => "text/plain"}, ["hello world"]}
  #   end
  # end
  #
  # Salt.run App.new
  # ```
  def self.run(app : Salt::App, **options)
    Salt::Server.new(**options).run(app)
  end

  # Specifies middleware to use in a stack.
  #
  # ```
  # class App < Salt::App
  #   def call(env)
  #     call_app(env)
  #     env.session.set("user", "foobar")
  #     {200, {"Content-Type" => "text/html"}, [Hello ", env.session.get("user")}
  #   end
  # end
  #
  # Salt.use Salt::Session::Cookie, secret: "<change me>"
  # Sale.run App.new
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
  alias ETag = Middlewares::ETag
  alias BasicAuth = Middlewares::BasicAuth

  # Set alias of environment of server

  {% for name in Server::Environment.constants %}
    {{ name.id }} = Server::Environment::{{ name.id }}.value
  {% end %}
end
