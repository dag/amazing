require 'amazing/string'
require 'amazing/config/dsl'
require 'amazing/widgets'

module Amazing
  class Config < Hash
    def initialize(config)
      @config = config
      load_dsl
    end

    private

    def load_dsl
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
          unless Widgets.constants.include?(self[:awesome][-1][:widgets][-1][:module])
            self[:awesome][-1][:widgets][-1][:module] = "Noop"
          end
        end
      end
    end
  end
end
