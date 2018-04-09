module Salt::Middlewares
  # Sets an "X-Runtime" response header, indicating the response
  # time of the request, in seconds
  #
  # ```
  # Salt.use Salt::Middlewares::Runtime, name: "Crystal"
  # # X-Runtime => Crystal-X-Runtime
  # ```
  class Runtime < App
    HEADER_NAME = "X-Runtime"

    @header_name : String

    def initialize(@app : App, name : String? = nil)
      @header_name = header_for(name)
    end

    def call(env)
      elapsed = elapsed do
        call_app(env)
      end

      unless headers.has_key?(@header_name)
        headers[@header_name] = elapsed
      end

      [status_code, headers, body]
    end

    private def elapsed(&block)
      start_time = Time.now
      block.call
      elapsed = Time.now - start_time
      elapsed.to_f.round(6).to_s
    end

    private def header_for(name)
      if name.to_s.empty?
        HEADER_NAME
      else
        "#{HEADER_NAME}-#{name}"
      end
    end
  end
end
