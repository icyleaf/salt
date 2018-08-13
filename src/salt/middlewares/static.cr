require "./file"

module Salt
  alias Static = Middlewares::Static

  module Middlewares
    # `Salt::Static` middleware intercepts requests for static files
    # (javascript files, images, stylesheets, etc) based on the url prefixes or
    # route mappings passed in the options, and serves them using a `Salt::File`
    # object. This allows a Rack stack to serve both static and dynamic content.
    #
    # ### Examples
    #
    # #### Quick Start
    #
    # It will search index file with "index.html" and "index.htm"
    #
    # ```
    # Salt.run Salt::Static.new(root: "/var/www/html")
    # ```
    #
    # #### Custom index file
    #
    # ```
    # Salt.run Salt::Static.new(root: "/var/www/html", index: "index.txt")
    # ```
    #
    # #### Set 404 page
    #
    # ```
    # Salt.run Salt::Static.new(root: "/var/www/html", not_found: "404.html")
    # ```
    class Static < App
      # Default index page files
      INDEX_FILES = ["index.html", "index.htm"]

      def initialize(app : App? = nil, root : String = ".",
                     @index : String? = nil, @not_found : String? = nil)
        @root = ::File.expand_path(root)
        @file_server = Salt::File.new(root: @root)
      end

      def call(env)
        if index_file = search_index_file(env.path)
          env.path = ::File.join(env.path, index_file)
        end

        if !::File.exists?(real_path(env.path)) && (not_found_file = @not_found)
          env.path = not_found_file
          @file_server.call(env, 404)
        else
          @file_server.call(env)
        end
      end

      private def search_index_file(path)
        # NOTE: fix crystal bug when File.join("abc", "/")
        # Removed if merged this PR: https://github.com/crystal-lang/crystal/pull/5915
        path = "" if path == "/"

        # Return given index file if exists
        if (index = @index) && ::File.exists?(real_path(path, index))
          return index
        end

        # Matching default index file
        INDEX_FILES.each do |name|
          file = real_path(path, name)
          return name if ::File.exists?(file)
        end
      end

      private def real_path(*files)
        ::File.join({@root} + files)
      end
    end
  end
end
