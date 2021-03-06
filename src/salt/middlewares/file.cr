module Salt
  alias File = Middlewares::File

  module Middlewares
    # `Salt::File` serves files below the **root** directory given, according to the
    # path info of the Salt request.
    #
    # ### Examples
    #
    # ```
    # # you can access 'passwd' file as http://localhost:9898/passwd
    # run Salt::File.new(root: "/etc")
    # ```
    #
    # Handlers can detect if bodies are a Salt::File, and use mechanisms
    # like sendfile on the **path**.
    class File < App
      ALLOWED_VERBS = %w[GET HEAD OPTIONS]
      ALLOW_HEADER  = ALLOWED_VERBS.join(", ")

      def initialize(@app : App? = nil, root : String = ".",
                     @headers = {} of String => String, @default_mime = "text/plain")
        @root = ::File.expand_path(root)
      end

      def call(env)
        get(env)
      end

      def call(env, status_code : Int32)
        get(env, status_code)
      end

      private def get(env, status_code = 200)
        unless ALLOWED_VERBS.includes?(env.method)
          return fail(405, "Method Not Allowed", {"Allow" => ALLOW_HEADER})
        end

        path_info = URI.unescape(env.path)
        return fail(400, "Bad Request") unless path_info.valid_encoding?

        path = ::File.join(@root, path_info)
        available = begin
          ::File.file?(path) && ::File.readable?(path)
        rescue Errno
          false
        end

        if available
          serving(env, path, status_code)
        else
          fail(404, "File not found: #{path_info}")
        end
      end

      private def serving(env, path, status_code)
        if env.options?
          return {200, {"Allow" => ALLOW_HEADER, "Content-length" => "0"}, [] of String}
        end

        last_modified = HTTP.format_time(::File.info(path).modification_time)
        return {304, {} of String => String, [] of String} if env.headers["HTTP_IF_MODIFIED_SINCE"]? == last_modified

        headers = {
          "Last-Modified"  => last_modified,
          "Content-Length" => ::File.size(path).to_s,
        }.merge(@headers)
        headers["Content-Type"] = "#{mime_type(path)}; charset=utf-8"

        body = String.build do |io|
          ::File.open(path) do |file|
            IO.copy(file, io)
          end
        end

        {status_code, headers, [body.to_s]}
      end

      private def fail(code : Int32, body : String, headers = {} of String => String)
        {
          code,
          {
            "Content-Type"   => "text/plain; charset=utf-8",
            "Content-Length" => body.bytesize.to_s,
            "X-Cascade"      => "pass",
          }.merge(headers),
          [body],
        }
      end

      private def mime_type(path : String)
        Mime.lookup(path, @default_mime)
      end
    end
  end
end
