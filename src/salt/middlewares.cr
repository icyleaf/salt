require "mime"

module Salt
  # `Salt::Middlewares` manages all about middlewares.
  module Middlewares
    @@middlewares = [] of Proc(App, App)

    # By default, use `Salt.use` instead this.
    def self.use(klass, **options)
      proc = ->(app : App) { klass.new(app, **options).as(App) }
      @@middlewares << proc
    end

    # Conversion middleweares into app
    def self.to_app(app : App) : App
      @@middlewares.reverse.reduce(app) { |a, e| e.call(a) }
    end

    # Clear all middlewares
    def self.clear
      @@middlewares.clear
    end
  end
end
