require "http/server/handler"

module Salt
  # `Salt::App` is a abstract class and implements the `call` method.
  #
  # You can use it to create any app or middlewares, all middlewares were based on it.
  # Method `call` must returns as `App::Response`.
  #
  # ### Example
  #
  # #### A simple app
  #
  # ```
  # class App < Salt::App
  #   def call(env)
  #     {200, {"content-type" => "text/plain"}, ["hello world"]}
  #   end
  # end
  #
  # Salt.run App.new
  # ```
  #
  # #### A simple middleware
  #
  # ```
  # class UpcaseBody < Salt::App
  #   def call(env)
  #     call_app env
  #     {status_code, headers, body.map &.upcase}
  #   end
  # end
  #
  # Salt.use UpcaseBody
  # Salt.run App.new
  # ```
  #
  # #### Middleware with options
  #
  # Options only accepts `Namedtuple` type, given the default value if pass as named arguments
  #
  # ```
  # class ServerName < Salt::App
  #   def initialize(@app, @name : String? = nil)
  #   end
  #
  #   def call(env)
  #     call_app env
  #
  #     if name = @name
  #       headers["Server"] = name
  #     end
  #
  #     {status_code, headers, body}
  #   end
  # end
  #
  # Salt.use ServerName, name: "Salt"
  # Salt.run App.new
  # ```
  #
  # Want know more examples, check all subclassess below.
  abstract class App
    alias Response = {Int32, Hash(String, String), Array(String)}

    property status_code = 200

    property headers = {} of String => String
    property body = [] of String

    def initialize(@app : App? = nil)
    end

    abstract def call(env) : Response

    protected def call_app(env : Environment) : Response
      if app = @app
        response = app.call(env)
        @status_code = response[0].as(Int32)
        @headers = response[1].as(Hash(String, String))
        @body = response[2].as(Array(String))
      end

      {@status_code, @headers, @body}
    end
  end
end
