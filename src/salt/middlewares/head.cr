module Salt::Middlewares
  # Salt::Head returns an empty body for all HEAD requests.
  # It leaves all other requests unchanged.
  class Head < App
    def call(env)
      call_app(env)

      return_body = (env.method == "HEAD") ? [] of String : body
      [status_code, headers, return_body]
    end
  end
end
