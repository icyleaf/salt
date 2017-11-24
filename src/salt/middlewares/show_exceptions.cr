require "ecr/macros"

module Salt::Middlewares
  class ShowExceptions < Salt::App
    def call(context)
        call_app(context)

        [status_code, headers, body]
      rescue e : Exception
        puts dump_exception(e)

        body = pretty_body(context, e)
        [
          500,
          {
            "Content-Type" => "text/html",
            "Content-Length" => body.bytesize.to_s,
          },
          [body],
        ]
    end

    private def dump_exception(exception)
      String.build do |io|
        io << "#{exception.class}: #{exception.message}\n"
        io << exception.backtrace.map { |l| "\t#{l}" }.join("\n")
      end.to_s
    end

    private def pretty_body(context, exception) : String
      request = context.request

      io = IO::Memory.new
      ECR.embed "#{__DIR__}/show_exceptions/views/layout.ecr", io

      io.to_s
    end
  end
end
