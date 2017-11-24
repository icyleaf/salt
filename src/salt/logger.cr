require "logger"

module Salt
  class Logger
    def initialize(@level : ::Logger::Severity = ::Loger::INFO)
    end
  end
end
