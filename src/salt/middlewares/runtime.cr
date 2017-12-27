module Salt::Middlewares
  class Runtime < Salt::App
    HEADER_NAME = "X-Runtime"

    def initialize(@app : App, name : String? = nil)
      @header_name = HEADER_NAME
      @header_name += "-#{name}" unless name.to_s.empty?
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
  end
end
