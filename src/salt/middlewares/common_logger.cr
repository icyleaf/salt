require "colorize"

module Salt
  alias CommonLogger = Middlewares::CommonLogger

  module Middlewares
    # `Salt::CommonLogger` forwards every request to the given app.
    #
    # ### Example
    #
    # #### Use built-in logger(`STDOUT`)
    #
    # ```
    # Salt.use Salt::CommonLogger
    # ```
    #
    # #### Use custom logger
    #
    # ```
    # Salt.use Salt::CommonLogger, io : File.open("development.log")
    # ```
    class CommonLogger < App
      FORMAT = %{%s |%s| %12s |%s %s%s}

      def initialize(@app : App, io : IO = STDERR)
        @logger = ::Logger.new(io)
        setting_logger
      end

      def call(env)
        began_at = Time.now
        response = call_app(env)
        log(env, status_code, headers, began_at)
        response
      end

      private def log(env, status_code, headers, began_at)
        @logger.info FORMAT % [
          Time.now.to_s("%Y/%m/%d - %H:%m:%S"),
          colorful_status_code(status_code),
          elapsed_from(began_at),
          colorful_method(env.method),
          env.path,
          env.query ? "?#{env.query}" : "",
        ]
      end

      private def colorful_status_code(status_code : Int32)
        code = " #{status_code.to_s} "
        case status_code
        when 300..399
          code.colorize.fore(:dark_gray).back(:white)
        when 400..499
          code.colorize.fore(:white).back(:yellow)
        when 500..999
          code.colorize.fore(:white).back(:red)
        else
          code.colorize.fore(:white).back(:green)
        end
      end

      private def colorful_method(method)
        raw = " %-10s" % method

        case method
        when "GET"
          raw.colorize.fore(:white).back(:blue)
        when "POST"
          raw.colorize.fore(:white).back(:green)
        when "PUT", "PATCH"
          raw.colorize.fore(:white).back(:yellow)
        when "DELETE"
          raw.colorize.fore(:white).back(:red)
        when "HEAD"
          raw.colorize.fore(:white).back(:magenta)
        else
          raw.colorize.fore(:dark_gray).back(:white)
        end
      end

      ELAPSED_LENGTH = 14

      private def elapsed_from(began_time)
        elapsed = Time.now - began_time
        millis = elapsed.total_milliseconds
        raw = if millis >= 1
                "#{millis.round(4)}ms"
              elsif (millis * 1000) >= 1
                "#{(millis * 1000).round(4)}µs"
              else
                "#{(millis * 1000 * 1000).round(4)}ns"
              end
      end

      private def setting_logger
        @logger.level = ::Logger::INFO
        @logger.formatter = ::Logger::Formatter.new do |severity, datetime, progname, message, io|
          io << message
        end
      end
    end
  end
end
