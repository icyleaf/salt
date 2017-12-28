module Salt
  module Middlewares
    @@middlewares = [] of Proc(Salt::App, Salt::App)

    def self.use(middleware_class, *args)
      proc = ->(app : Salt::App) { middleware_class.new(app, *args).as(Salt::App) }
      @@middlewares << proc
    end

    def self.to_app(run : Salt::App) : Salt::App
      @@middlewares.reverse.reduce(run) { |a, e| e.call(a) }
    end

    def self.clear
      @@middlewares.clear
    end
  end
end

require "./middlewares/*"
