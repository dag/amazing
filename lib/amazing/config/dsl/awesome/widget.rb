module Amazing
  class Config < Hash
    class Dsl
      class Awesome
        class Widget
          attr_reader :options
          attr_reader :identifier
          attr_reader :properties

          def initialize(identifier, opts={}, &block)
            @identifier, @options = identifier, opts
            @properties = {}
            instance_eval(&block) if block
          end

          def set(opts)
            @options.merge!(opts)
          end

          def property(name, &block)
            @properties[name] = block
          end
        end
      end
    end
  end
end
