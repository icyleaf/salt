require "uri"

module Salt
  class Environment
    delegate version, to: @request
    delegate headers, to: @request

    @request : HTTP::Request

    def initialize(@context : HTTP::Server::Context)
      @request = @context.request
    end

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
        uri.scheme
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
          method == {{ method.id.stringify}}
        end
      {% end %}
    end

    module Params
      delegate query_params, to: @request
    end

    include URI
    include Methods
  end
end
