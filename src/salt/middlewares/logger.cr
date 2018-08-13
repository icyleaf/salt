module Salt
  alias Logger = Middlewares::Logger

  module Middlewares
    # Sets up env.logger to write to STDOUT stream
    #
    # ### Example
    #
    # ```
    # Salt.use Salt::Middlewares::Logger, io: File.open("development.log", "w"), level: Logger::ERROR
    # Salt.use Salt::Middlewares::Logger, level: Logger::ERROR
    # ```
    class Logger < App
      def initialize(@app : App, @io : IO = STDOUT, @progname = "salt",
                     @level : ::Logger::Severity = ::Logger::INFO,
                     @formatter : ::Logger::Formatter? = nil)
      end

      def call(env)
        logger = ::Logger.new(@io)
        logger.level = @level
        logger.progname = @progname
        logger.formatter = @formatter.not_nil! if @formatter

        env.logger = logger
        call_app(env)
      end
    end
  end
end
