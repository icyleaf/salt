module Salt::Middlewares
  class Runtime < Salt::App
    HEADER_NAME = "X-Runtime"

    def initialize(@app : App, name : String? = nil)
      @header_name = HEADER_NAME
      @header_name += "-#{name}" unless name.to_s.empty?
    end

    def call(context)
      start_time = Time.now
      call_app(context)
      request_time = Time.now - start_time

      unless headers.has_key?(@header_name)
        headers[@header_name] = request_time.to_f.round(6).to_s
      end

      [status_code, headers, body]
    end
  end
end
