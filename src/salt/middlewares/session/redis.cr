require "./abstract/session_hash"
require "./abstract/id"
require "redis"
require "json"

module Salt::Middlewares::Session
  # Salt::Session::Redis provides simple cookie based session management.
  # Session data was stored in redis. The corresponding session key is
  # maintained in the cookie.
  #
  # Setting :expire_after to 0 would note to the Memcache server to hang
  #   onto the session data until it would drop it according to it's own
  #   specifications. However, the cookie sent to the client would expire
  #   immediately.
  #
  # **Note that** redis does drop data before it may be listed to expire. For
  # a full description of behaviour, please see redis's documentation.
  #
  # Example:
  #
  # ```
  # use Salt::Session::Redis, server: "redis://localhost:6379/0",
  #                           namspace: "salt:session"
  # ```
  #
  # All parameters are optional.
  class Redis < Abstract::ID
    DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.to_h.merge({
      :server => "redis://localhost:6379/0",
      :namespace => "salt:session"
    })

    def initialize(@app : App, **options)
      super

      @options = merge_options(DEFAULT_OPTIONS, **options)
      @pool = ::Redis.new(url: @options[:server].as(String))
    end

    def get_session(env : Environment, session_id : String?)
      unless session_id && (session_data = get_key(session_id))
        session_id = generate_session_id
        session_data = Hash(String, String).new
        unless set_key(session_id, session_data)
          raise "Session collision on '#{session_id.inspect}'"
        end
      end

      Abstract::SessionStored.new(session_id, session_data)
    end

    def set_session(env : Environment, session_id : String, session : Hash(String, String))
      set_key(session_id, session, expiry)
      session_id
    end

    def destory_session(env : Environment, session_id : String)
      del_key(session_id)
      generate_session_id unless @options[:drop]
    end

    def finalize
      @pool.close
    end

    private def generate_session_id
      loop do
        session_id = super
        break session_id if get_key(session_id).empty?
      end
    end

    private def expiry : Int32
      if expiry = @options[:expire_after]
        return expiry.as(Int32) + 1
      end

      0
    end

    private def get_key(key : String) : Hash(String, String)
      hash = Hash(String, String).new
      @pool.hgetall(namespace_to(key)).each_slice(2) do |array|
        hash[array.first.as(String)] = array.last.as(String)
      end
      hash
    end

    private def del_key(key : String)
      @pool.del(namespace_to(key))
    end

    private def set_key(key : String, hash : Hash(String, _), expiry = 0)
      hash.each do |field, value|
       @pool.hset(namespace_to(key), field, value.to_s)
      end
      set_key_expire(key, expiry) if expiry > 0

      true
    end

    private def set_key(key : String, json : JSON::Any, expiry = 0)
      json.each do |field, value|
        @pool.hset(namespace_to(key), field, value.as_s)
      end
      set_key_expire(key, expiry) if expiry > 0

      true
    end

    private def set_key_expire(key : String, expiry : Int32)
      @pool.expire(namespace_to(key), expiry)
    end

    private def namespace_to(key : String)
      "#{@options[:namespace]}:#{key}"
    end
  end
end
