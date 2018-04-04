# :nodoc:
module HTTP
  struct Params
    def self.new
      HTTP::Params.parse ""
    end

    delegate empty?, to: raw_params
  end
end
