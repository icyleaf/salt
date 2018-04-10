require "./abstract/*"

require "openssl/hmac"
require "base64"
require "json"
require "zlib"

module Salt::Middlewares::Session
  # Salt::Session::Cookie provides simple cookie based session management.
  #
  # By default, the session is a Crystal Hash stored as base64 encoded marshalled
  # data set to `key` (default: `salt.session`).  The object that encodes the
  # session data is configurable and must respond to **encode** and **decode**.
  # Both methods must take a string and return a string.
  #
  # When the secret key is set, cookie data is checked for data integrity.
  # The old secret key is also accepted and allows graceful secret rotation.
  #
  # Example:
  #
  # ```
  # use Salt::Session::Cookie, key: "salt.session",
  #                            domain: "foobar.com",
  #                            expire_after: 2592000,
  #                            secret: "change_me",
  #                            old_secret: "change_me"
  # ```
  #
  # All parameters are optional.
  class Cookie < Abstract::Persisted
    abstract class Base64
      abstract def encode(data)
      abstract def encode(data)

      protected def encode_str(data : String)
        ::Base64.encode(data)
      end

      protected def decode_str(data : String)
        ::Base64.decode_string(data)
      end

      protected def stringify_hash(data)
        hash = Hash(String, String).new
        data.each do |key, value|
          hash[key.to_s] = value.to_s
        end
        hash
      end

      class JSON < Base64
        def encode(data)
          encode_str(data.to_json)
        end

        def decode(data)
          stringify_hash(::JSON.parse(decode_str(data)))
        end
      end

      class ZipJSON < Base64
        def encode(data)
          io = IO::Memory.new

          writer = Zlib::Writer.new(io)
          writer.print(data.to_json)
          writer.close

          encode_str(io.to_s)
        end

        def decode(data)
          io = IO::Memory.new(decode_str(data))

          reader = Zlib::Reader.new(io)
          raw = String::Builder.build do |builder|
            IO.copy(reader, builder)
          end
          reader.close

          stringify_hash(::JSON.parse(raw))
        end
      end
    end

    class Identity
      def encode(str)
        str
      end

      def decode(str)
        str
      end
    end

    getter coder : Base64

    @secrets : Array(String)
    @hmac : Symbol

    def initialize(@app : App, **options)
      @secrets = compact_secrets(**options)
      @hmac = options.fetch(:hmac, :sha1).as(Symbol)
      @coder = options.fetch(:coder, Base64::ZipJSON.new).as(Base64)

      puts <<-MSG
      SECURITY WARNING: No secret option provided to Salt::Middlewares::Session::Cookie.
      This poses a security threat. It is strongly recommended that you
      provide a secret to prevent exploits that may be possible from crafted
      cookies. This will not be supported in future versions of Salt, and
      future versions will even invalidate your existing user cookies.

      Called from: #{caller[0]}.
      MSG unless secure?(options)

      super(@app, **options)
    end

    def find_session(env : Environment, session_id : String?)
      data = unpacked_cookie_data(env)
      stored = persistent_session_id!(data)
      stored.session_id = stored.data["session_id"].as(String)
      stored
    end

    def write_session(env : Environment, session_id : String, session : Hash(String, String))
      session = session.merge({SESSION_ID => session_id})
      session_data = @coder.encode(session)
      digest = generate_hmac(@secrets.first, session_data)

      session_data = "#{session_data}--#{digest}" if @secrets.first
      if session_data.size > (4096 - @key.size)
        puts "Warning! Salt::Middlewares::Session::Cookie data size exceeds 4K."
        nil
      else
        session_data
      end
    end

    def delete_session(env : Environment, session_id : String)
      # Nothing to do here, data is in the client
      generate_session_id if env.session.options[:drop]?
    end

    def extract_session_id(env)
      unpacked_cookie_data(env)["session_id"]?
    end

    def unpacked_cookie_data(env)
      if (session_cookie = env.cookies[@key]?) && !session_cookie.value.empty?
        encrypted_data = session_cookie.value
        digest, session_data = encrypted_data.reverse.split("--", 2)
        digest = digest.reverse if digest
        session_data = session_data.reverse if session_data

        return coder.decode(session_data) if digest_match?(session_data, digest)
      end

      Hash(String, String).new
    end

    def persistent_session_id!(data : Hash(String, String), session_id : String? = nil)
      session_id ||= generate_session_id
      data[SESSION_ID] = session_id unless data.has_key?(SESSION_ID)

      Abstract::SessionStored.new(session_id, data)
    end

    private def generate_hmac(key : String, data : String)
      OpenSSL::HMAC.hexdigest(@hmac, key, data)
    end

    private def secure?(options)
      @secrets.size >= 1 || (options[:coder]? && options[:let_coder_handle_secure_encoding]?)
    end

    private def digest_match?(data, digest)
      return false unless data && digest

      @secrets.any? do |secret|
        target = generate_hmac(secret, data)
        return false unless digest.bytesize == target.bytesize

        l = digest.bytes
        r, i = 0, -1
        target.each_byte { |v| r |= v ^ l[i+=1] }
        r == 0
      end
    end

    private def compact_secrets(**options)
      Array(String).new.tap do |arr|
        if secret = options[:secret]?
          arr << secret
        end

        if old_secret = options[:old_secret]?
          arr << old_secret
        end
      end
    end
  end
end
