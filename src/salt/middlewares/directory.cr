module Salt::Middlewares
  # Salt::Directory serves entries below the **root** given, according to the
  # path info of the Salt request. If a directory is found, the file's contents
  # will be presented in an html based index. If a file is found, the env will
  # be passed to the specified **app**.
  #
  # If **app** is not specified, a Salt::File of the same **root** will be used.
  #
  # Example:
  #
  # ```
  # Salt.run Salt::Directory.new(root: "~/")
  # ```
  class Directory < App
    def initialize(app : App? = nil, root : String = ".")
      @root = ::File.expand_path(root)
      app = app || Salt::File.new(root: root)

      super(app)
    end

    def call(env)
      path_info = URI.unescape(env.path)
      if bad_request = check_bad_request(path_info)
        bad_request
      elsif forbidden = check_forbidden(path_info)
        forbidden
      else
        list_path(env, path_info)
      end
    end

    private def list_path(env, path_info)
      path = ::File.join(@root, path_info)
      if ::File.readable?(path)
        if ::File.file?(path)
          @app.not_nil!.call(env)
        else
          list_directory(path_info, path)
        end
      else
        fail(404, "No such file or directory")
      end
    end

    private def list_directory(path_info, path)
      files = if path_info == "/"
                # Hide link in top index
                [] of Array(String)
              else
                [["../", "Parent Directory", "-", "Directory", "-"]]
              end

      glob_path = ::File.join(path, "*")
      url_path = path_info.split("/").map do |part|
        URI.escape(part)
      end
      # Hacks to remove the last empty string to apply in url path with File.join
      url_path.delete_at(-1)

      Dir[glob_path].sort.each do |node|
        next unless stat = stat(node)

        file_name = ::File.basename(node)
        next if file_name.starts_with?(".")

        file_url = ::File.join(url_path + [URI.escape(file_name)])
        if stat.directory?
          file_url += "/"
          file_name += "/"
        end
        file_type = stat.directory? ? "Directory" : "File"
        file_size = stat.directory? ? "-" : filesize_format(stat.size)

        files << [file_url, file_name, file_size.to_s, file_type.to_s, stat.mtime.to_s]
      end

      [
        200,
        {
          "Content-Type" => "text/html; charset=utf-8",
        },
        [pretty_body(path_info, files)],
      ]
    end

    private def check_bad_request(path_info)
      return if path_info.valid_encoding?

      fail(400, "Bad Request")
    end

    private def check_forbidden(path_info)
      return unless path_info.includes?("..")

      fail(403, "Forbidden")
    end

    private def fail(code : Int32, body : String, headers = {} of String => String)
      [
        code,
        {
          "Content-Type"   => "text/plain; charset=utf-8",
          "Content-Length" => body.bytesize.to_s,
          "X-Cascade"      => "pass",
        }.merge(headers),
        [body],
      ]
    end

    private def stat(node)
      ::File.stat(node)
    rescue Errno
      return nil
    end

    private def pretty_body(root, files) : String
      io = IO::Memory.new
      ECR.embed("#{__DIR__}/views/directory/layout.ecr", io)
      io.to_s
    end

    FILESIZE_FORMAT = {
      "%.1fT" => 1099511627776,
      "%.1fG" => 1073741824,
      "%.1fM" => 1048576,
      "%.1fK" => 1024,
    }

    private def filesize_format(int)
      human_size = 0.to_f
      FILESIZE_FORMAT.each do |format, size|
        return format % (int.to_f / size) if int >= size
      end

      "#{int}B"
    end
  end
end
