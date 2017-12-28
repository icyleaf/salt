module Salt::Exceptions
  class Error < ::Exception; end

  class NotFoundMiddleware < Error; end
end
