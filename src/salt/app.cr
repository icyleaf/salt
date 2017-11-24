require "http/server/handler"

module Salt
  abstract class App
    alias Response = Array(Int32 | Hash(String, String) | Array(String))

    property status_code = 200
    property headers = {} of String => String
    property body = [] of String

    def initialize(@app : App? = nil)
    end

    abstract def call(context) : Response

    protected def call_app(context)
      if app = @app
        response = app.call(context)
        @status_code = response[0].as(Int32)
        @headers = response[1].as(Hash(String, String))
        @body = response[2].as(Array(String))
      end
    end
  end
end