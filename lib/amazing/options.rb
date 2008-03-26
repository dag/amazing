# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'optparse'

module Amazing

  # Parse and manage command line options
  class Options
    include Enumerable

    def initialize(args)
      @options = {}
      @options[:config] = "#{ENV["HOME"]}/.amazing/config.yml"
      @options[:loglevel] = "info"
      @options[:include] = []
      @options[:autoinclude] = true
      @options[:update] = []
      @args = args
      @parser = OptionParser.new do |opts|
        opts.on("-c", "--config FILE", "Configuration file (~/.amazing/config.yml)") do |config|
          @options[:config] = config
        end
        opts.on("-l", "--log-level LEVEL", "Severity threshold (info)") do |level|
          @options[:loglevel] = level
        end
        opts.on("-i", "--include SCRIPT", "Include a widgets script") do |script|
          @options[:include] << script
        end
        opts.on("--no-auto-include", "Don't auto include from ~/.amazing/widgets/") do
          @options[:autoinclude] = false
        end
        opts.on("-u", "--update WIDGET", "Update a widget and exit") do |widget|
          @options[:update] << widget
        end
        opts.on("-w", "--list-widgets", "List available widgets") do
          @options[:listwidgets] = true
        end
        opts.on("-t", "--test-widget WIDGET", "Dump field values for a widget") do |widget|
          @options[:test] = widget
        end
        opts.on("-h", "--help", "You're looking at it") do
          @options[:help] = true
        end
      end
    end

    def each
      @options.keys.each do |key|
        yield key
      end
    end

    def parse(args=@args)
      @parser.parse!(args)
    end

    def help
      @parser.help
    end

    def [](option)
      @options[option]
    end

    def []=(option, value)
      @options[option] = value
    end
  end
end
