require "./middlewares/session/abstract/session_hash"
require "uri"
require "tempfile"

module Salt
  # `Salt::Environment` provides a convenient interface to a Salt environment.
  # It is stateless, the environment **env** passed to the constructor will be directly modified.
  struct Environment
    @request : HTTP::Request
    @response : HTTP::Server::Response

    def initialize(@context : HTTP::Server::Context)
      @request = @context.request
      @response = @context.response

      parse_params
    end

    property? logger : ::Logger?

    # Depend on `Salt::Logger` middleware
    def logger
      unless logger?
        raise Exceptions::NotFoundMiddleware.new("Missing Logger middleware, use Salt::run add it.")
      end

      @logger.not_nil!
    end

    property? session : Salt::Middlewares::Session::Abstract::SessionHash?

    # Depend on `Salt::Session` middleware
    def session
      unless session?
        raise Exceptions::NotFoundMiddleware.new("Missing Session middleware, use Salt::run add it.")
      end

      @session.not_nil!
    end

    delegate version, to: @request
    delegate headers, to: @request

    module URL
      delegate full_path, to: @request
      delegate path, to: @request
      delegate query, to: @request

      def path=(value)
        @request.path = value
      end

      def query=(value)
        @request.query = value
      end

      def url : String
        String.build do |io|
          io << base_url << full_path
        end
      end

      def base_url : String?
        host_with_port  ? "#{scheme}://#{host_with_port}" : nil
      end

      def full_path : String
        uri.full_path
        # query ? "#{path}?#{query.not_nil!}" : path
      end

      def scheme : String
        uri.scheme || "http"
      end

      def ssl? : Bool
        scheme == "https"
      end

      def host : String?
        if host = @request.host
          return host
        end

        uri.host
      end

      def host_with_port : String?
        if host_with_port = @request.host_with_port
          return host_with_port
        end

        return unless host

        String.build do |io|
          io << host
          unless [80, 443].includes?(port)
            io << ":" << port
          end
        end
      end

      def port : Int32
        uri.port || (ssl? ? 443 : 80)
      end

      @uri : URI?

      private def uri
        (@uri ||= URI.parse(@context.request.resource)).not_nil!
      end
    end

    module Methods
      NAMES = %w(GET HEAD PUT POST PATCH DELETE OPTIONS)

      delegate method, to: @request

      {% for method in NAMES %}
        # Checks the HTTP request method (or verb) to see if it was of type {{ method.id }}
        def {{ method.id.downcase }}?
          method == {{ method.id.stringify }}
        end
      {% end %}
    end

    module Parameters
      delegate query_params, to: @request

      @params_parsed = false
      @params = HTTP::Params.new

      def params
        return @params if @params_parsed && @request == @context.request
        parse_params
      end

      def form_data? : Bool
        if content_type = @request.headers["content_type"]?
          return content_type.starts_with?("multipart/form-data")
        end

        false
      end

      @files = {} of String => UploadFile

      # return files of Request body
      def files
        @files
      end

      private def parse_params
        @params = form_data? ? parse_multipart : parse_body

        # Add query params
        if !query_params.size.zero?
          query_params.each do |key, value|
            @params.add(key, value)
          end
        end

        @params_parsed = true
        @params
      end

      private def parse_body
        raws = case body = @request.body
               when IO
                 body.gets_to_end
               when String
                 body.to_s
               else
                 ""
               end

        HTTP::Params.parse raws
      end

      private def parse_multipart : HTTP::Params
        params = HTTP::Params.new

        HTTP::FormData.parse(@request) do |part|
          next unless part

          name = part.name
          if filename = part.filename
            @files[name] = UploadFile.new(part)
          else
            params.add name, part.body.gets_to_end
          end
        end

        params
      end
    end

    module Cookies
      @cookies : CookiesProxy?

      def cookies
        @cookies ||= CookiesProxy.new(@context)
        @cookies.not_nil!
      end

      class CookiesProxy
        def initialize(@context : HTTP::Server::Context)
        end

        def add(name : String, value : String, path : String = "/",
                expires : Time? = nil, domain : String? = nil,
                secure : Bool = false, http_only : Bool = false,
                extension : String? = nil)
          cookie = HTTP::Cookie.new(name, value, path, expires, domain, secure, http_only, extension)
          add(cookie)
        end

        def add(cookie : HTTP::Cookie)
          @context.response.cookies << cookie
        end

        def <<(cookie : HTTP::Cookie)
          add(cookie)
        end

        def get(name : String)
          @context.request.cookies[name]
        end

        def get?(name : String)
          @context.request.cookies[name]?
        end

        forward_missing_to @context.request.cookies
      end
    end
    private struct UploadFile
      getter filename : String
      getter tempfile : Tempfile
      getter size : UInt64?
      getter created_at : Time?
      getter modifed_at : Time?
      getter headers : HTTP::Headers

      def initialize(part : HTTP::FormData::Part)
        @filename = part.filename.not_nil!
        @size = part.size
        @created_at = part.creation_time
        @modifed_at = part.modification_time
        @headers = part.headers

        @tempfile = Tempfile.new(@filename)
        ::File.open(@tempfile.path, "w") do |f|
          IO.copy(part.body, f)
        end
      end
    end

    include URL
    include Methods
    include Parameters
    include Cookies
  end
end
