require 'amazing/config/dsl/awesome'

module Amazing
  class Config < Hash
    class Dsl
      attr_reader :awesome_statusbars

      def initialize(config=nil, &block)
        @awesome_statusbars = []
        import(config)
        import(&block)
      end

      def import(config=nil, &block)
        instance_eval(File.read(config)) if config
        instance_eval(&block) if block
      end

      def awesome(opts={}, &block)
        @awesome_statusbars << Awesome.new(opts, &block)
      end
    end
  end
end
