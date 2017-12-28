module Salt::Middlewares
  class Logger < Salt::App
    HEADER_NAME = "X-Runtime"

    def initialize(@app : App, @io : IO = STDOUT, @level : ::Logger::Severity = ::Logger::INFO)
    end

    def call(env)
      logger = ::Logger.new(@io)
      logger.level = @level

      env.logger = logger
      call_app(env)
    end
  end
end
