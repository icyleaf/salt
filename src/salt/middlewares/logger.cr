module Salt::Middlewares
  # Sets up env.logger to write to STDOUT stream
  #
  # ```
  # Salt.use Salt::Middlewares::Logger, io: File.open("development.log", "w"), level: Logger::ERROR
  # Salt.use Salt::Middlewares::Logger, level: Logger::ERROR
  # ```
  class Logger < App
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
