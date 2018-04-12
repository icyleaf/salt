require "crypto/subtle"
require "base64"

module Salt
  module Middlewares
    # `Salt::BasicAuth` implements HTTP Basic Authentication, as per RFC 2617.
    #
    # Initialize with the Salt application that you want protecting,
    # and a block that checks if a username and password pair are valid.
    #
    # ### Rules for resouces
    #
    # #### All paths
    #
    # By defaults, it sets `[]` for all paths
    #
    # #### A list of paths/files to protect.
    #
    # `["/admin", "/config/database.yaml"]`
    #
    # ### Examples
    #
    # #### protect for all paths
    #
    # ```
    # Salt.use Salt::Middlewares::BasicAuth, user: "foo", password: "bar"
    # ```
    #
    # #### resources is a list of files/paths to protect
    #
    # ```
    # Salt.use Salt::Middlewares::BasicAuth, user: "foo", password: "bar", resources: ["/admin"]
    # ```
    class BasicAuth < App
      AUTH_STRING = "Authorization"

      def initialize(@app : App, @user = "", @password = "",
                     @resources = [] of String, @authenticator : Proc(String, String?)? = nil,
                     @realm = "Login Required", @realm_charset : String? = nil)
        raise "Missing user & password" if @user.empty? && password.empty?
      end

      def call(env)
        return call_app(env) unless resources?(env)
        return unauthorized unless auth_provided?(env)
        return bad_request unless auth_basic?(env)

        if username = auth_valid?(env)
          env.auth_user = username
          return call_app(env)
        end

        unauthorized
      end

      private def unauthorized
        body = "401 Unauthorized"
        {
          401,
          {
            "Content-Type"     => "text/plain",
            "Content-Lengt"    => body.bytesize.to_s,
            "WWW-Authenticate" => realm,
          },
          [body],
        }
      end

      def bad_request
        body = "400 Bad request"
        {
          400,
          {
            "Content-Type"  => "text/plain",
            "Content-Lengt" => body.bytesize.to_s,
          },
          [body],
        }
      end

      def auth_valid?(env) : String?
        _, value = auth_value(env)
        if auth = @authenticator
          auth.call(value)
        else
          authorize?(value)
        end
      end

      def authorize?(value)
        user, password = Base64.decode_string(value).split(":", 2)
        if Crypto::Subtle.constant_time_compare(@user, user) &&
           Crypto::Subtle.constant_time_compare(@password, password)
          user
        end
      end

      def resources?(env)
        return true if @resources.empty?

        @resources.each do |path|
          return true if env.path.starts_with?(path)
        end

        false
      end

      def auth_provided?(env) : Bool
        env.headers.has_key?(AUTH_STRING)
      end

      def auth_basic?(env) : Bool
        auth_value(env).first.downcase == "basic"
      end

      def auth_value(env) : Array(String)
        env.headers[AUTH_STRING].split(" ", 2)
      end

      def realm : String
        if charset = @realm_charset
          %Q(Basic realm="#{@realm}", charset="#{charset}")
        else
          %Q(Basic realm="#{@realm}")
        end
      end
    end
  end

  class Environment
    property auth_user : String?
  end
end
