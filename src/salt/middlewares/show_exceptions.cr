require "ecr/macros"

module Salt
  alias ShowExceptions = Middlewares::ShowExceptions

  module Middlewares
    # `Salt::ShowExceptions` catches all exceptions raised from the app it wraps.
    # It shows a useful backtrace with the sourcefile and
    # clickable context, the whole Salt environment and the request
    # data.
    #
    # **Be careful** when you use this on public-facing sites as it could
    # reveal information helpful to attackers.
    class ShowExceptions < App
      def call(env)
        call_app(env)

        [status_code, headers, body]
      rescue e : Exception
        puts dump_exception(e)

        body = pretty_body(env, e)
        {
          500,
          {
            "Content-Type"   => "text/html",
            "Content-Length" => body.bytesize.to_s,
          },
          [body],
        }
      end

      private def dump_exception(exception)
        String.build do |io|
          io << "#{exception.class}: #{exception.message}\n"
          io << exception.backtrace.map { |l| "    #{l}" }.join("\n")
        end.to_s
      end

      private def pretty_body(env, exception) : String
        io = IO::Memory.new
        ECR.embed "#{__DIR__}/views/show_exceptions/layout.ecr", io
        io.to_s
      end
    end
  end
end
