require 'amazing/config/dsl/awesome/widget'

module Amazing
  class Config < Hash
    class Dsl
      class Awesome
        attr_reader :options
        attr_reader :widgets

        def initialize(opts={}, &block)
          @options = opts
          @widgets = []
          instance_eval(&block)
        end

        def set(opts)
          @options.merge!(opts)
        end

        def widget(identifier, opts={}, &block)
          @widgets << Widget.new(identifier, opts, &block)
        end
      end
    end
  end
end
