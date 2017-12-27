require "http/server"
require "logger"
require "./ext/*"

module Salt
  class Server
    property logger : Logger
    property options : Hash(String, String|Int32|Bool)

    def initialize(**options)
      @options = parse_options **options
      @logger = Logger.new(STDOUT)
    end

    def run(run_app : Salt::App)
      @run_app = run_app
      display_info
      run_server
    end

    def wrapped_app
      @wrapped_app ||= build_app(app).as(Salt::App)
    end

    def app
      @app ||= Salt::Middlewares.to_app(run_app).as(Salt::App)
    end

    def run_app
      @run_app.not_nil!
    end

    private def run_server
      HTTP::Server.new(@options["host"].as(String), @options["port"].as(Int32), [
        Salt::Middlewares::Core.new(wrapped_app)
      ]).listen(reuse_port: false)
    end

    private def build_app(app : Salt::App)
      middlewares[options["environment"]].each do |klass|
        app = klass.new(app)
      end
      app
    end

    private def middlewares
      @middlewares ||= {
        "development" => [
          Salt::Middlewares::CommonLogger.as(Salt::App.class),
          Salt::Middlewares::ShowExceptions.as(Salt::App.class),
        ],
        "deployment" => [
          Salt::Middlewares::CommonLogger.as(Salt::App.class),
        ]
      }.as(Hash(String, Array(Salt::App.class)))
    end

    private def parse_options(**options)
      Hash(String, String|Int32|Bool).new.tap do |obj|
        obj["environment"] = options.fetch(:environment, ENV["SALT_ENV"]? || "development")
        obj["host"] = options.fetch(:host, obj["environment"].to_s == "development" ? "localhost" : "0.0.0.0")
        obj["port"] = options.fetch(:port, 9898)
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
