module Salt
  module Middlewares
    @@middlewares = [] of Proc(Salt::App, Salt::App)
    # @@middlewares = {
    #   "development" => [] of Proc(Salt::App, Salt::App),
    #   "deployment" => [] of Proc(Salt::App, Salt::App)
    # }

    def self.use(middleware, *args)
      proc = ->(app : Salt::App) { middleware.new(app, *args).as(Salt::App) }
      @@middlewares << proc
    end

    def self.to_app(run : Salt::App)
      @@middlewares.reverse.reduce(run) { |a, e| e.call(a) }
    end

    def self.each(&block)
      @@middlewares.each &block
    end

    def self.clear
      @@middlewares.clear
    end

    class Core
      include HTTP::Handler

      def initialize(@app : Salt::App)
      end

      def call(context)
        response = @app.call(context)
        status_code = response[0].as(Int32)
        headers = response[1].as(Hash(String, String))
        body = response[2].as(Array(String))

        context.response.status_code = status_code
        headers.each do |name, value|
          context.response.headers[name] = value
        end

        body.each do |line|
          context.response << line
        end
      end
    end
  end
end

require "./middlewares/*"
