require "ecr/macros"

module Salt::Middlewares
  class ShowExceptions < Salt::App
    def call(env)
      call_app(env)

      [status_code, headers, body]
    rescue e : Exception
      puts dump_exception(e)

      body = pretty_body(env, e)
      [
        500,
        {
          "Content-Type"   => "text/html",
          "Content-Length" => body.bytesize.to_s,
        },
        [body],
      ]
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
