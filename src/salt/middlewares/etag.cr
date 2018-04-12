require "openssl"

module Salt::Middlewares
  class ETag < App
    ETAG_STRING           = "ETag"
    CACHE_CONTROL_STRING  = "Cache-Control"
    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"

    def initialize(@app : App, @no_cache_control : String? = nil, @cache_control = DEFAULT_CACHE_CONTROL)
    end

    def call(env)
      call_app(env)

      if etag_status? && !skip_caching?
        digest, new_body = digest_body(body)
        headers[ETAG_STRING] = %(W/"#{digest}") if digest
      end

      unless headers[CACHE_CONTROL_STRING]?
        if digest
          headers[CACHE_CONTROL_STRING] = @cache_control if @cache_control
        else
          headers[CACHE_CONTROL_STRING] = @no_cache_control.not_nil! if @no_cache_control
        end
      end

      {status_code, headers, body}
    end

    private def digest_body(body)
      parts = [] of String
      digest = nil

      body.each do |part|
        parts << part
        (digest ||= OpenSSL::Digest.new("SHA256")).update(part) unless part.empty?
      end

      [digest && digest.hexdigest.byte_slice(0, 32), parts]
    end

    private def etag_status?
      [200, 201].includes?(@status_code)
    end

    private def skip_caching?
      @headers[CACHE_CONTROL_STRING]?.to_s.includes?("no-cache") ||
        @headers.has_key?(ETAG_STRING) || @headers.has_key?("Last-Modified")
    end
  end
end
