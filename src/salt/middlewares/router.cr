module Salt
  module Middlewares
    # `Salt::Router` is a lightweight HTTP Router.
    #
    #  **This middleware still in early stage**
    #
    # ### Example
    #
    # #### Graceful way
    # ```
    # class Dashboard < Salt::App
    #   def call(env)
    #     {200, {"Content-Type" => "text/plain"}, ["dashboard"] }
    #   end
    # end
    #
    # Salt.run Salt::Router do |r|
    #   r.get "/dashboard", to: Dashboard.new
    #   r.get "/helo" do |env|
    #     {200, {"Content-Type" => "text/plain"}, ["hello world"]}
    #   end
    #
    #   r.post "/post", to: -> (env : Salt::Environment) { {200, {"Content-Type" => "text/plain"}, ["post success"] }
    #
    #   r.redirect "/home", to: "/dashboard", code: 302
    #
    #   r.not_found enabled: true
    #   # Or custom not found page
    #   r.not_found do |env|
    #     {404, {"Content-Type" => "application/json"}. [{"message" => "404 not found"}.to_json]}
    #   end
    # end
    # ```
    #
    # #### Strict way
    #
    # ```
    # Salt.run Salt::Router, rules: -> (r : Salt::Router::Drawer) {
    #   r.get "/hello" do |env|
    #     {200, {"Content-Type" => "text/plain"}, ["hello"]}
    #   end
    #
    #  # Must return nil as Proc argument.
    #  nil
    # }
    # ```
    class Router < App
      def self.new(app : App? = nil, &rules : Drawer ->)
        new(app, rules: rules)
      end

      def initialize(@app : App? = nil, @rules : Proc(Drawer, Nil)? = nil)
      end

      def call(env)
        if response = draw(env)
          return response
        end

        call_app(env)
      end

      private def draw(env)
        return unless routes = @rules

        drawer = Drawer.new(env)
        routes.call(drawer)

        if response = drawer.find(env.method, env.path)
          response
        else
          drawer.try_not_found
        end
      end

      class Drawer
        METHODS = %w(GET POST PUT DELETE PATCH HEAD OPTIONS)

        @routes = [] of Node

        def initialize(@env : Environment)
        end

        def find(method : String, path : String)
          each do |node|
            return node.response if method == node.method && path == node.path
          end
        end

        {% for name in METHODS %}
          {% method = name.id.downcase %}
          def {{ method }}(path : String, &block : Environment -> App::Response)
            {{ method }}(path, to: block)
          end

          def {{ method }}(path : String, to block : Environment -> App::Response)
            response = block.call(@env)
            @routes << Node.new({{ name.id.stringify }}, path, response)
          end

          def {{ method }}(path : String, to app : Salt::App)
            response = app.call(@env)
            @routes << Node.new({{ name.id.stringify }}, path, response)
          end
        {% end %}

        def redirect(from : String, to : String, status_code = 302)
          method = "GET"
          if find(method, to)
            response = {status_code, {"Location" => to}, [] of String}
            @routes << Node.new(method, from, response)
          end
        end

        def not_found(enabled : Bool)
          return unless enabled

          body = "Not found"
          response = {
            404,
            {
              "Content-Type" => "text/plain",
              "Content-Length" => body.bytesize.to_s
            },
            [body]
          }

          @routes << Node.new("ANY", "*", response)
        end

        def not_found(&block : Environment -> App::Response)
          not_found(to: block)
        end

        def not_found(to block : Environment -> App::Response)
          response = block.call(@env)
          @routes << Node.new("ANY", "*", response)
        end

        def not_found(to app : Salt::App)
          response = block.call(@env)
          @routes << Node.new("ANY", "*", response)
        end

        def try_not_found
          find("ANY", "*")
        end

        def each
          @routes.each do |node|
            yield node
          end
        end

        record Node, method : String, path : String, response : App::Response
      end

    end

    # Hacks accepts block to run `Salt::Router` middleware
    def self.use(klass, **options, &block : Router::Drawer ->)
      proc = ->(app : App) { klass.new(app, **options, &block).as(App) }
      @@middlewares << proc
    end
  end

  # Hacks accepts block to run `Salt::Router` middleware
  def self.use(middleware, **options, &block : Router::Drawer ->)
    Middlewares.use(middleware, **options, &block)
  end

  # Hacks accepts block to run `Salt::Router` middleware
  def self.run(app : Salt::App, **options, &block : Router::Drawer ->)
    Salt::Server.new(**options).run(app)
  end
end
