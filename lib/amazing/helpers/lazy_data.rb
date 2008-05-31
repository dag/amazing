require 'amazing/lazy'

module Amazing
  module Helpers
    module LazyData
      def lazy(&block)
        Lazy.new(&block)
      end
    end
  end
end
