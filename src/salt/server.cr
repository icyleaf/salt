require "http/server"
require "./ext/*"

module Salt
  class Server
    property logger : ::Logger
    property options : Hash(String, String|Int32|Bool)

    @run : App?
    @app : App?
    @wrapped_app : App?

    def initialize(**options)
      @options = parse_options **options
      @logger = ::Logger.new(STDOUT)
    end

    def run(run : Salt::App)
      @run = run
      if @options["debug"].as(Bool)
        pp @options
        pp run
      end

      display_info
      HTTP::Server.new(@options["host"].as(String), @options["port"].as(Int32), [
        Salt::Middlewares::Core.new(wrapped_app)
      ]).listen
    end

    def app
      @app ||= Salt::Middlewares.to_app(run)
    end

    def wrapped_app
      @wrapped_app ||= build_app(app)
    end

    def run
      @run.not_nil!
    end

    # @middlewares = {} of String => Array(Salt::App.class)
    private def middlewares
      {
        "development" => [
          Salt::Middlewares::CommonLogger,
          Salt::Middlewares::ShowExceptions,
        ],
        "deployment" => [
          Salt::Middlewares::CommonLogger,
        ]
      }
    end

    private def build_app(app)
      middlewares[options["environment"]].each do |klass|
        app = klass.new(app)
      end
      app
    end

    private def parse_options(**options)
      Hash(String, String|Int32|Bool).new.tap do |obj|
        obj["environment"] = options.fetch(:environment, ENV["SALT_ENV"]? || "development")
        obj["host"] = options.fetch(:host, obj["environment"].to_s == "development" ? "localhost" : "0.0.0.0")
        obj["port"] = options.fetch(:port, 9876)

        obj["debug"] = options.fetch(:debug, false)

        ENV["SALT_ENV"] = obj["environment"].to_s
      end
    end

    private def display_info
      @logger.info "HTTP::Server is start at http://#{@options["host"]}:#{@options["port"]}/"
      @logger.info "Use Ctrl-C to stop"
    end
  end
end
