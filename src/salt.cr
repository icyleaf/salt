require "./salt/*"

module Salt
  # Run http server and takes an argument that is an Salt::App that responds to #call
  #
  # ```
  # class App < Salt::App
  #   def call(context)
  #     [200, {"Content-Type" => "text/plain"}, ["hello world"]]
  #   end
  # end
  #
  # Salt.run App.new, port: 9876
  # ```
  # def self.run(app : Salt::App, host : String? = nil, port : Int32? = nil)
  #   Salt::Server.new(host: host, port: port).run(app)
  # end

  def self.run(app : Salt::App, **options)
    Salt::Server.new(**options).run(app)
  end

  # Specifies middleware to use in a stack.
  #
  # ```
  # class Middleware < Salt::App
  #   def call(context)
  #     call_app context
  #     [200, {"Content-Type" => "text/html"}, ["<h1>", "Hello Salt", "</h1>"]]
  #   end
  # end
  #
  # Salt.use Salt::Middlewares::Runtime
  # Sale.use Middleware
  # ```
  def self.use(middleware, *args)
    Salt::Middlewares.use(middleware, *args)
  end
end
