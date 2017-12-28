module Salt::Middlewares
  # Sets up env.logger to write to STDOUT stream
  class Logger < Salt::App
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
