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
    # Salt.use Salt::Router do |r|
    #   r.get "/lambda/1" do |env|
    #     {200, {"Content-Type" => "text/plain"}, ["hello"]}
    #   end
    #
    #   r.get "/lambda/2", to: -> (env : Salt::Environment) { {200, {"Content-Type" => "text/plain"}, ["hello"] }
    #   r.get "/dashboard", to: Dashboard.new
    # end
    # ```
    #
    # #### Strict way
    #
    # ```
    # Salt.use Salt::Router, rules: -> (r : Salt::Router::Drawer) {
    #   r.get "/hello" do |env|
    #     {200, {"Content-Type" => "text/plain"}, ["hello"]}
    #   end
    # }
    # ```
    class Router < App
      def self.new(app : App, not_found = false, &rules : Drawer ->)
        new(app, not_found: not_found, rules: rules)
      end

      def initialize(@app : App, @rules : Proc(Drawer, Nil)? = nil, @not_found = false)
      end

      def call(env)
        if response = draw(env)
          return response
        end

        if @not_found
          not_found(env)
        else
          call_app(env)
        end
      end

      private def draw(env)
        return unless routes = @rules

        drawer = Drawer.new(env)
        routes.call(drawer)

        pp env.method
        pp env.path

        drawer.each do |node|
          pp node
          return node.response if env.method == node.method && env.path == node.path
        end
      end

      private def not_found(env)
        body = "Not found"
        {
          404,
          {
            "Content-Type" => "text/plain",
            "Content-Length" => body.bytesize.to_s
          },
          [body]
        }
      end

      class Drawer
        METHODS = %w(GET POST PUT DELETE PATCH HEAD OPTIONS)

        @routes = [] of Node

        def initialize(@env : Environment)
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

        def each
          @routes.each do |node|
            yield node
          end
        end

        record Node, method : String, path : String, response : App::Response
      end

    end

    # Only apply to `Salt::Router` middleware
    def self.use(klass, **options, &block : Router::Drawer ->)
      proc = ->(app : App) { klass.new(app, **options, &block).as(App) }
      @@middlewares << proc
    end
  end

  # Only apply to `Salt::Router` middleware
  def self.use(middleware, **options, &block : Router::Drawer ->)
    Middlewares.use(middleware, **options, &block)
  end
end
