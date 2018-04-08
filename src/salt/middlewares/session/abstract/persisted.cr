require "random/secure"

module Salt::Middlewares::Session::Abstract
  abstract class Persisted < App
    SESSION_KEY = "salt.session"
    SESSION_ID  = "session_id"

    DEFAULT_OPTIONS = {
      :key             => SESSION_KEY,
      :path            => "/",
      :domain          => nil,
      :expire_after    => nil,
      :secure          => false,
      :http_only       => true,
      :defer           => false,
      :renew           => false,
      :cookie_only     => true,
      :session_id_bits => 128,
    }

    @options : Hash(Symbol, String | Bool | Int32 | Nil)

    def initialize(@app : App, **options)
      @options = merge_options(**options)

      @key = @options[:key].as(String)
      @session_id_bits = @options[:session_id_bits].as(Int32)
      @session_id_length = (@session_id_bits / 4).as(Int32)
    end

    def call(env)
      prepare_session(env)
      call_app(env)
      commit_session(env)

      [status_code, headers, body]
    end

    def commit_session(env)
      session = env.session
      session.load! unless loaded_session?(session)

      session_id = session.id
      session_data = session.to_h.delete_if { |_,v| v.nil? }

      if data = write_session(env, session_id, session_data)
        http_only = @options[:http_only].as(Bool)
        secure = @options[:secure].as(Bool)
        cookie = HTTP::Cookie.new(@key, data, expires: expires, http_only: http_only, secure: secure)
        set_cookie(env, cookie)
      else
        puts "Warning! #{self.class.name} failed to save session. Content dropped."
      end
    end

    def loaded_session?(session)
      !session.is_a?(SessionHash) || session.loaded?
    end

    def set_cookie(env, cookie)
      if env.cookies[@key]? != cookie.value || cookie.expires
        env.cookies.add(cookie)
        return true
      end

      false
    end

    def load_session(env : Environment)
      session_id = current_session_id(env)
      find_session(env, session_id)
    end

    def extract_session_id(env)
      session_id = env.cookies[@key]?.try(&.value)
      session_id ||= env.params[@key]? unless @options[:cookie_only].as(Bool)
      session_id
    end

    def session_exists?(env : Environment) : Bool
      !current_session_id(env).nil?
    end

    abstract def find_session(env : Environment, session_id : String?) : SessionStored
    abstract def write_session(env : Environment, session_id : String?, session : Hash(String, String)) : String?
    abstract def delete_session(env : Environment, session_id : String) : Bool

    private def prepare_session(env : Environment)
      session_was = env.session? ? env.session : nil
      session = SessionHash.new(self, env)
      session.options = @options.dup
      session.merge!(session_was) if session_was
      env.session = session
    end

    private def generate_session_id
      Random::Secure.hex(@session_id_length)
    end

    private def current_session_id(env : Environment) : String?
      env.session.id
    end

    private def merge_options(**options)
      merged_options = DEFAULT_OPTIONS
      options.each do |key, value|
        merge_options[key] = value if merged_options.has_key?(key)
      end

      merged_options
    end

    private def expires : Time?
      if expire_after = @options[:expire_after]?
        return Time.now + expire_after.as(Int32).seconds
      elsif max_age = @options[:max_age]?
        return Time.now + max_age.as(Int32).seconds
      end

      nil
    end
  end
end
