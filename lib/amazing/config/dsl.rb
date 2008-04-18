require 'amazing/config/dsl/awesome'
require 'amazing/numeric'

module Amazing
  class Config < Hash
    class Dsl
      attr_reader :awesome_statusbars

      def initialize(config=nil, &block)
        @awesome_statusbars = []
        @relative_path = File.dirname(config)
        import(config)
        import(&block)
      end

      def import(config=nil, &block)
        if config
          config = "#@relative_path/#{config}" if config[0] != ?/
          instance_eval(File.read(config))
        end
        instance_eval(&block) if block
      end

      def awesome(opts={}, &block)
        @awesome_statusbars << Awesome.new(opts, &block)
      end
    end
  end
end
