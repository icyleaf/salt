{% if Crystal::VERSION < "0.26.0" %}
  # :nodoc:
  # PR was merged and included to v0.26.0: https://github.com/crystal-lang/crystal/pull/6241
  module HTTP
    struct Params
      def self.new
        HTTP::Params.parse ""
      end

      delegate empty?, to: raw_params
    end
  end
{% end %}
