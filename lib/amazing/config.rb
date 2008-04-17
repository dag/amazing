require 'amazing/string'
require 'amazing/config/dsl'
require 'amazing/config/yaml'

module Amazing
  class Config < Hash
    def initialize(config)
      @config = config
      case File.extname(@config)[1..-1].to_sym
      when :rb
        from_dsl
      when :yml, :yaml
        from_yaml
      end
    end

    private

    def from_dsl
      dsl = Dsl.new(@config)
      self[:awesome] = []
      dsl.awesome_statusbars.each do |awesome|
        self[:awesome] << {}
        self[:awesome][-1][:screen] = awesome.options[:screen] || 0
        self[:awesome][-1][:statusbar] = awesome.options[:statusbar] || "mystatusbar"
        self[:awesome][-1][:widgets] = []
        awesome.widgets.each do |widget|
          self[:awesome][-1][:widgets] << {}
          self[:awesome][-1][:widgets][-1][:identifier] = widget.identifier
          self[:awesome][-1][:widgets][-1][:properties] = widget.properties
          self[:awesome][-1][:widgets][-1].merge!(widget.options)
          self[:awesome][-1][:widgets][-1][:module] ||= widget.identifier
          self[:awesome][-1][:widgets][-1][:property] ||= "text"
          self[:awesome][-1][:widgets][-1][:module] = self[:awesome][-1][:widgets][-1][:module].to_s.camel_case
        end
      end
    end

    def from_yaml
      yaml = Yaml.new(@config)
      self[:awesome] = []
      yaml["awesome"].each do |awesome|
        self[:awesome] << {}
        self[:awesome][-1][:screen] = awesome["screen"] || 0
        self[:awesome][-1][:statusbar] = awesome["statusbar"] || "mystatusbar"
        self[:awesome][-1][:widgets] = []
        awesome["widgets"].each do |widget|
          self[:awesome][-1][:widgets] << {}
          case widget
          when Hash
            self[:awesome][-1][:widgets][-1][:identifier] = widget.keys[0]
            widget.values[0].each do |key, value|
              self[:awesome][-1][:widgets][-1][key.to_sym] = value
            end
            self[:awesome][-1][:widgets][-1][:module] ||= widget.keys[0]
          when String
            self[:awesome][-1][:widgets][-1][:identifier] = widget
            self[:awesome][-1][:widgets][-1][:module] = widget
          end
          self[:awesome][-1][:widgets][-1][:property] ||= "text"
          self[:awesome][-1][:widgets][-1][:module] = self[:awesome][-1][:widgets][-1][:module].to_s.camel_case
        end
      end
    end
  end
end
