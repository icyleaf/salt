require "uri"

module Salt
  class Environment
    @request : HTTP::Request

    def initialize(@context : HTTP::Server::Context)
      @request = @context.request
    end

    setter logger : ::Logger?

    # Depend on `Salt::Middlewares::Logger` middleware
    def logger
      if @logger.nil?
        raise Salt::Exceptions::NotFoundMiddleware.new("Missing `Salt.use Salt::Middlewares::Logger` before Salt::run.")
      end

      @logger.not_nil!
    end

    delegate version, to: @request
    delegate headers, to: @request

    module URI
      delegate path, to: @request
      delegate query, to: @request

      def url
        url = "#{base_url}#{full_path}"
        url += "##{fragment}" if fragment
        url
      end

      def base_url
        "#{scheme}://#{host_with_port}"
      end

      def full_path
        query ? "#{path}?#{query.not_nil!}" : path
      end

      def fragment
        uri.fragment
      end

      def scheme
        uri.scheme || "http"
      end

      def ssl?
        scheme == "https"
      end

      def host
        if host = @request.host
          return host
        end

        uri.host
      end

      def host_with_port
        if host_with_port = @request.host_with_port
          return host_with_port
        end

        String.build do |io|
          io << host
          io << ":" << port unless [80, 443].includes?(port)
        end.to_s
      end

      def port
        uri.port
      end

      @uri : ::URI?

      private def uri
        (@uri ||= ::URI.parse(@context.request.resource)).not_nil!
      end
    end

    module Methods
      delegate method, to: @request

      {% for method in %w(GET HEAD PUT POST PATCH DELETE OPTIONS) %}
        # Checks the HTTP request method (or verb) to see if it was of type {{ method.id }}
        def {{ method.id.downcase }}?
          method == {{ method.id.stringify }}
        end
      {% end %}
    end

    module Params
      delegate query_params, to: @request

      @params_parsed = false
      @params = HTTP::Params.new

      def params
        return @params if @params_parsed && @request == @context.request

        @params_parsed = true
        if content_type = @request.headers["content_type"]?
          @params = case content_type
                    when .includes?("multipart/form-data")
                      parse_multipart(@request)
                    else
                      parse_body(@request.body)
                    end
        end

        @params
      end

      @files = {} of String => HTTP::FormData::Part

      # return files of Request body
      def files
        @files
      end

      private def parse_body(body)
        raws = case body
               when IO
                 body.gets_to_end
               when String
                 body.to_s
               else
                 ""
               end

        HTTP::Params.parse raws
      end

      private def parse_multipart(request) : HTTP::Params
        params = HTTP::Params.new

        HTTP::FormData.parse(request) do |part|
          next unless part

          name = part.name
          if filename = part.filename
            @files[name] = part
          else
            params.add name, part.body.gets_to_end
          end
        end

        params
      end
    end

    module Cookies
      delegate cookies, to: @request
    end

    include URI
    include Methods
    include Params
    include Cookies
  end
end
