require "http/server"

module Salt
  class Server
    property host : String
    property port : Int32
    property logger : ::Logger

    def initialize(host : String? = nil, port : Int32? = nil)
      @host = host || "0.0.0.0"
      @port = port || 9876

      @logger = ::Logger.new(STDOUT)
    end

    def run(run : Salt::App)
      display_info

      app = Salt::Middlewares.to_app(run)
      HTTP::Server.new(@host, @port, [Salt::Middlewares::Core.new(app)]).listen
    end

    private def display_info
      @logger.info "HTTP::Server is start at http://#{host}:#{port}/"
      @logger.info "Use Ctrl-C to stop"
    end
  end
end
