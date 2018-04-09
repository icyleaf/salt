module Salt::Middlewares::Session::Abstract
  abstract class ID < Persisted
    def find_session(env : Environment, session_id : String?)
      get_session(env, session_id)
    end

    def write_session(env : Environment, session_id : String, session : Hash(String, String))
      set_session(env, session_id, session)
    end

    def delete_session(env : Environment, session_id : String)
      destory_session(env, session_id)
    end
  end
end
