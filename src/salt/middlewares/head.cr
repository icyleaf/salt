module Salt::Middlewares
  # `Salt::Head` returns an empty body for all HEAD requests.
  # It leaves all other requests unchanged.
  class Head < App
    def call(env)
      call_app(env)

      {status_code, headers, (env.method == "HEAD") ? [] of String : body}
    end
  end
end
