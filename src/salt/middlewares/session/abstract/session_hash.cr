module Salt::Middlewares::Session::Abstract
  # SessionHash is responsible to lazily load the session from store.
  class SessionHash
    include Enumerable(SessionHash)

    property options : Hash(Symbol, Bool | Int32 | String | Nil)

    @exists : Bool?
    @id : String?
    property data : Hash(String, String)

    def initialize(@store : Persisted, @env : Environment, @loaded = false)
      @exists = nil
      @options = Hash(Symbol, Bool | Int32 | String | Nil).new

      @id = nil
      @data = Hash(String, String).new
    end

    def []=(key : String, value : String)
      set(key, value)
    end

    def set(key : String, value : String)
      load_for_write!
      @data[key] = value
    end

    def [](key : String)
      get(key)
    end

    def get(key : String)
      load_for_read!
      @data[key]
    end

    def []?(key : String)
      get?(key)
    end

    def get?(key : String)
      load_for_read!
      @data[key]?
    end

    def has_key?(key : String)
      load_for_read!
      @data.has_key?(key)
    end

    def fetch(key : String, default = nil)
      @data.fetch(key, default)
    end

    def delete(key : String)
      @data.delete(key)
    end

    def to_h
      load_for_read!
      @data.dup
    end

    def merge!(hash : SessionHash)
      load_for_write!
      @data.merge(stringify_keys(hash))
    end

    def each
      load_for_read!
      @data.each do |key, value|
        yield({key, value})
      end
    end

    def delete(key : String)
      load_for_write!
      @data.delete(key)
    end

    def clear
      load_for_write!
      @data.clear
    end

    def destroy
      clear
      @id = @store.delete_session(@env, id)
    end

    def id
      return @id if @loaded || !@id.nil?
      @id = @store.extract_session_id(@env)
    end

    def exists?
      return @exists if !@exists.nil?

      @exists ||= @store.session_exists?(@env)
      @exists.not_nil!
    end

    def loaded?
      @loaded
    end

    def empty?
      load_for_read!
      @data.empty?
    end

    def keys
      load_for_read!
      @data.keys
    end

    def values
      load_for_read!
      @data.values
    end

    def load!
      stored = @store.load_session(@env)

      @id = stored.session_id
      @data = stored.data
      @loaded = true
    end

    private def load_for_read!
      load! if !loaded? && exists?
    end

    private def load_for_write!
      load! unless loaded?
    end

    private def stringify_keys(session : SessionHash)
      data = Hash(String, String).new
      session.each do |key, value|
        data[key.to_s] = value
      end
      data
    end
  end

  struct SessionStored
    property session_id, data

    def initialize(@session_id : String, @data : Hash(String, String))
    end
  end
end
