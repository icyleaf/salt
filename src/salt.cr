require "./salt/*"
require "./salt/ext/*"

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
end
