# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

module Amazing

  # Raised by widgets, and is then rescued and logged
  class WidgetError < Exception
  end

  # Parent class for widget construction, example:
  #
  #   class Clock < Widget
  #     description "Displays date and time"
  #     dependency "some/library", "how to get the library (url, gem name...)"
  #     option :time_format, "Time format as described in DATE(1)", "%R"
  #     field :time, "Formatted time"
  #     default "@time"
  # 
  #     init do
  #       @time = Time.now.strftime(@time_format)
  #       raise WidgetError, "An error occured!" if some_error?
  #     end
  #   end
  class Widget
    def initialize(identifier=nil, format=nil, opts={})
      self.class.dependencies.each do |name, description|
        begin
          require name
        rescue LoadError
          raise WidgetError, "Missing dependency #{name.inspect}#{if description then " [#{description}]" end}"
        end
      end
      @identifier, @format = identifier, format
      self.class.options.each do |key, value|
        value = opts[key.to_s] || value[:default]
        instance_variable_set "@#{key}".to_sym, value
      end
      self.class.fields.each do |key, value|
        instance_variable_set "@#{key}".to_sym, value[:default]
      end
      instance_eval(&self.class.init) if self.class.init
    end

    def self.description(description=nil)
      if description
        @description = description
      else
        @description
      end
    end

    def self.dependency(name, description=nil)
      @dependencies ||= {}
      @dependencies[name] = description
    end

    def self.dependencies
      @dependencies || {}
    end

    def self.option(name, description=nil, default=nil)
      @options ||= {}
      @options[name] = {:description => description, :default => default}
    end

    def self.options
      @options || {}
    end

    def self.field(name, description=nil, default=nil)
      @fields ||= {}
      @fields[name] = {:description => description, :default => default}
    end

    def self.fields
      @fields || {}
    end

    def self.default(format=nil, &block)
      if format
        @default = format
      elsif block
        @default = block
      else
        @default
      end
    end

    def self.init(&block)
      if block
        @init = block
      else
        @init
      end
    end

    def formatize
      if @format
        instance_eval(@format)
      else
        case self.class.default
        when Proc
          instance_eval(&self.class.default)
        when String
          instance_eval(self.class.default)
        end
      end
    end
  end
end
