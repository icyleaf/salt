require "./file"

module Salt
  alias Directory = Middlewares::Directory

  module Middlewares
    # `Salt::Directory` serves entries below the **root** given, according to the
    # path info of the Salt request. If a directory is found, the file's contents
    # will be presented in an html based index. If a file is found, the env will
    # be passed to the specified **app**.
    #
    # If **app** is not specified, a Salt::File of the same **root** will be used.
    #
    # ### Examples
    #
    # ```
    # Salt.run Salt::Directory.new(root: "~/")
    # ```
    class Directory < App
      def initialize(app : App? = nil, root : String = ".")
        @root = ::File.expand_path(root)
        app = app || Salt::Middlewares::File.new(root: root)

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
        real_path = ::File.join(@root, path_info)
        if ::File.readable?(real_path)
          if ::File.file?(real_path)
            @app.not_nil!.call(env)
          else
            list_directory(path_info, real_path)
          end
        else
          fail(404, "No such file or directory")
        end
      end

      private def list_directory(path_info, real_path)
        files = load_files(path_info)

        glob_path = ::File.join(real_path, "*")
        path = URI.escape(path_info) do |byte|
          URI.unreserved?(byte) || byte.chr == '/'
        end

        Dir[glob_path].sort.each do |node|
          next unless stat = info(node)

          name = ::File.basename(node)
          next if name.starts_with?(".")

          url = ::File.join(path + URI.escape(name))
          url += "/" if stat.directory?
          name += "/" if stat.directory?
          icon = stat.directory? ? directory_icon : file_icon
          size = stat.directory? ? "" : filesize_format(stat.size)

          files << [icon, name, url, size.to_s, stat.modification_time.to_local.to_s]
        end

        {
          200,
          {
            "Content-Type" => "text/html; charset=utf-8",
          },
          [pretty_body(path_info, files)],
        }
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

      private def load_files(path_info)
        if path_info == "/"
          [] of Array(String)
        else
          [["", "..", "../", "", ""]]
        end
      end

      private def directory_icon
        <<-HTML
        <svg class="octicon octicon-file-directory" viewBox="0 0 14 16" version="1.1" width="14" height="16" aria-hidden="true"><path fill-rule="evenodd" d="M13 4H7V3c0-.66-.31-1-1-1H1c-.55 0-1 .45-1 1v10c0 .55.45 1 1 1h12c.55 0 1-.45 1-1V5c0-.55-.45-1-1-1zM6 4H1V3h5v1z"></path></svg>
        HTML
      end

      private def file_icon
        <<-HTML
        <svg class="octicon octicon-file" viewBox="0 0 12 16" version="1.1" width="12" height="16" aria-hidden="true"><path fill-rule="evenodd" d="M6 5H2V4h4v1zM2 8h7V7H2v1zm0 2h7V9H2v1zm0 2h7v-1H2v1zm10-7.5V14c0 .55-.45 1-1 1H1c-.55 0-1-.45-1-1V2c0-.55.45-1 1-1h7.5L12 4.5zM11 5L8 2H1v12h10V5z"></path></svg>
        HTML
      end

      private def info(node)
        ::File.info(node)
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
end
