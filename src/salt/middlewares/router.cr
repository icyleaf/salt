require "radix"

module Salt
  alias Router = Middlewares::Router

  module Middlewares
    # `Salt::Router` is a lightweight HTTP Router.
    #
    # ### Example
    #
    # It Dependency [radix](https://github.com/luislavena/radix), you need add to `shard.yml` and install first.
    #
    # #### Graceful way
    #
    # ```
    # class Dashboard < Salt::App
    #   def call(env)
    #     {200, {"Content-Type" => "text/plain"}, ["dashboard"] }
    #   end
    # end
    #
    # Salt.run Salt::Router.new do |r|
    #   r.get "/dashboard", to: Dashboard.new
    #   r.get "/users/:id" do |env|
    #     {200, {"Content-Type" => "text/plain"}, ["hello user #{env.params["id"]}"]}
    #   end
    #
    #   r.post "/post", to: -> (env : Salt::Environment) { {200, {"Content-Type" => "text/plain"}, ["post success"] }
    #
    #   r.redirect "/home", to: "/dashboard", code: 302
    #
    #   r.not_found
    #   # Or custom not found page, also it accepts Proc and Salt::App as argument.
    #   r.not_found do |env|
    #     {404, {"Content-Type" => "application/json"}. [{"message" => "404 not found"}.to_json]}
    #   end
    # end
    # ```
    #
    # #### Strict way
    #
    # ```
    # Salt.run Salt::Router, rules: ->(r : Salt::Router::Drawer) {
    #   r.get "/hello" do |env|
    #     {200, {"Content-Type" => "text/plain"}, ["hello"]}
    #   end
    #
    #   # Must return nil as Proc argument.
    #   nil
    # }
    # ```
    class Router < App
      alias Action = Environment -> Response

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
        return unless rules = @rules

        drawer = Drawer.new(env)
        rules.call(drawer)

        if response = drawer.find(env.method, env.path)
          response
        else
          drawer.try_not_found
        end
      end

      class Drawer
        METHODS = %w(GET POST PUT DELETE PATCH HEAD OPTIONS)

        @tree = Radix::Tree(Action).new # [] of Node

        def initialize(@env : Environment)
        end

        def find(method : String, path : String)
          r = @tree.find("/#{method}#{path}")

          if r.found?
            response = r.payload
            r.params.each do |key, value|
              @env.params.add(key, value)
            end

            response.call(@env)
          end
        end

        {% for name in METHODS %}
          {% method = name.id.downcase %}

          # Define {{ name.id }} route with block
          #
          # ```
          # Salt::Router.new do |draw|
          #   draw.{{ method }} "/{{ method }}" do |env|
          #     {200, { "Content-Type" => "text/plain"} , [] of String}
          #   end
          # end
          # ```
          def {{ method }}(path : String, &block : Action)
            {{ method }}(path, to: block)
          end

          # Define {{ name.id }} route with `Proc(Salt::Environment, Salt::App::Response)` or `Salt::App`
          #
          # ```
          # Salt::Router.new do |draw|
          #   # Proc
          #   draw.{{ method }} "/{{ method }}", to: -> (env : Salt::Environment) {
          #     {200, { "Content-Type" => "text/plain"} , [] of String}
          #   }
          #
          #   # Or use Salt::App
          #   draw.{{ method }} "/{{ method }}", to: {{ method.id.capitalize }}App.new
          # end
          # ```
          def {{ method }}(path : String, to block : Action | Salt::App | App::Response)
            @tree.add(radix_path({{ name.id.upcase.stringify }}, path), action_with(block))
          end
        {% end %}

        # Define redirect route
        #
        # By defaults is `302`
        #
        # ```
        # Salt::Router.new do |draw|
        #   draw.redirect "/source", to: "/destination", status_code: 301
        #   # Or simple way as you like
        #   draw.redirect "/source", "/destination", 301
        # end
        # ```
        def redirect(from : String, to : String, status_code = 302)
          method = "GET"
          if find(method, to)
            response = {status_code, {"Location" => to}, [] of String}.as(App::Response)
            @tree.add(radix_path(method, from), action_with(response))
          end
        end

        # Support a default not found page
        #
        # ```
        # Salt::Router.new do |draw|
        #   # returns not found page directly
        #   draw.not_found
        # end
        # ```
        def not_found
          not_found do |env|
            body = "Not found"
            {
              404,
              {
                "Content-Type"   => "text/plain",
                "Content-Length" => body.bytesize.to_s,
              },
              [body],
            }
          end
        end

        # Define a custom not found page with block
        #
        # ```
        # Salt::Router.new do |draw|
        #   draw.not_found do |env|
        #     {200, {"Content-Type" => "text/plain"}, [] of String}
        #   end
        # end
        # ```
        def not_found(&block : Action)
          not_found(to: block)
        end

        # Define a custom not found page witb Proc or `Salt::App`
        #
        # ```
        # Salt::Router.new do |draw|
        #   # Proc
        #   draw.{{ method }} "/{{ method }}", to: -> (env : Salt::Environment) {
        #     {200, { "Content-Type" => "text/plain"} , [] of String}
        #   }
        #
        #   # Or use Salt::App
        #   draw.{{ method }} "/{{ method }}", to: NotFoundApp.new
        # end
        # ```
        def not_found(to block : Action | Salt::App | App::Response)
          @tree.add(radix_path("ANY", "/404"), action_with(block))
        end

        def try_not_found
          find("ANY", "/404")
        end

        private def action_with(response : Action | Salt::App | App::Response) : Action
          case response
          when Action
            response.as(Action)
          when Salt::App
            ->(env : Environment) { response.as(Salt::App).call(env).as(App::Response) }
          when App::Response
            ->(env : Environment) { response.as(App::Response) }
          else
            raise "Not match response. it must be Action, Salt::App or App::Response"
          end
        end

        private def radix_path(method, path)
          "/#{method.upcase}#{path}"
        end
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
