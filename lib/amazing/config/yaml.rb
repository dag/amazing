require 'yaml'

module Amazing
  class Config < Hash
    class Yaml < Hash
      def initialize(config)
        merge!(YAML.load_file(config))
      end
    end
  end
end
