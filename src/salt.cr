require "./salt/*"

module Salt
  # def self.run(app : -> Salt::Middlewares::Context, host : String? = nil, port : Int32? = nil)
  #   Salt::Server.new(host: host, port: port).run(app)
  # end

  def self.run(app : Salt::App, host : String? = nil, port : Int32? = nil)
    Salt::Server.new(host: host, port: port).run(app)
  end

  def self.use(middleware, *args)
    Salt::Middlewares.use(middleware, *args)
  end
end
