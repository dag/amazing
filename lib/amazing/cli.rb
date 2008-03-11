# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'logger'
require 'amazing/options'
require 'amazing/x11/display_name'
require 'yaml'
require 'amazing/widget'
require 'amazing/proc_file'
require 'amazing/widgets'
require 'amazing/awesome'
require 'timeout'
require 'thread'

module Amazing

  # Command line interface runner
  #
  #   CLI.run(ARGV)
  class CLI
    def initialize(args)
      @args = args
      @log = Logger.new(STDOUT)
      @options = Options.new(@args)
      begin
        @display = X11::DisplayName.new
      rescue X11::EmptyDisplayName => e
        @log.warn("#{e.message}, falling back on :0")
        @display = X11::DisplayName.new(":0")
      rescue X11::InvalidDisplayName => e
        @log.fatal("#{e.message}, exiting")
        exit 1
      end
    end

    def run
      trap("SIGINT") do
        @log.fatal("Received SIGINT, exiting")
        exit
      end
      @options.parse
      show_help if @options[:help]
      set_loglevel
      parse_config
      load_scripts
      list_widgets if @options[:listwidgets]
      wait_for_sockets
      @awesome = Awesome.new(@display.display)
      explicit_updates unless @options[:update].empty?
      update_non_interval
      count = 0
      loop do
        @config["widgets"].each do |screen, widgets|
          widgets.each do |widget_name, settings|
            if settings["every"] && count % settings["every"] == 0
              update_widget(screen, widget_name)
            end
          end
        end
        count += 1
        sleep 1
      end
    end

    private

    def show_help
      puts @options.help
      exit
    end

    def set_loglevel
      begin
        @log.level = Logger.const_get(@options[:loglevel].upcase)
      rescue NameError
        @log.error("Unsupported log level #{@options[:loglevel].inspect}")
        @log.level = Logger::INFO
      end
    end

    def load_scripts
      scripts = @options[:include]
      @config["include"].each do |script|
        script = "#{File.dirname(@options[:config])}/#{script}" if script[0] != ?/
        scripts << script
      end
      if @options[:autoinclude]
        scripts << Dir["#{ENV["HOME"]}/.amazing/*.rb"]
      end
      scripts.flatten.each do |script|
        if File.exist?(script)
          @log.debug("Loading script #{script.inspect}")
          Widgets.module_eval(File.read(script))
        else
          @log.error("No such widget script #{script.inspect}")
        end
      end
    end

    def list_widgets
      longest_widget_name = Widgets.constants.inject {|a,b| a.length > b.length ? a : b }.length
      Widgets.constants.each do |widget|
        widget_class = Widgets.const_get(widget)
        puts "%-#{longest_widget_name}s : %s" % [widget, widget_class.description]
        widget_class.dependencies.each do |name, description|
          puts "#{" " * longest_widget_name}     require '#{name}' # #{description}"
        end
        widget_class.options.each do |name, info|
          puts "#{" " * longest_widget_name}     #{name}: <#{info[:description]}> || #{info[:default].inspect}"
        end
        widget_class.fields.each do |name, info|
          puts "#{" " * longest_widget_name}     @#{name} = <#{info[:description]}> || #{info[:default].inspect}"
        end
        puts
      end
      exit
    end

    def parse_config
      @log.debug("Parsing configuration file")
      begin
        @config = YAML.load_file(@options[:config])
      rescue
        @log.fatal("Unable to parse configuration file, exiting")
        exit 1
      end
      @config["include"] ||= []
    end

    def wait_for_sockets
      @log.debug("Waiting for awesome control socket for display #{@display.display}")
      begin
        Timeout.timeout(30) do
          sleep 1 until File.exist?("#{ENV["HOME"]}/.awesome_ctl.#{@display.display}")
          @log.debug("Got socket for display #{@display.display}")
        end
      rescue Timeout::Error
        @log.fatal("Socket for display #{@display.display} not created within 30 seconds, exiting")
        exit 1
      end
    end

    def update_non_interval
      @config["widgets"].each do |screen, widgets|
        widgets.each do |widget_name, settings|
          next if settings["every"]
          update_widget(screen, widget_name)
        end
      end
    end

    def explicit_updates
      @config["widgets"].each do |screen, widgets|
        widgets.each_key do |widget_name|
          next unless @options[:update].include? widget_name
          update_widget(screen, widget_name, false)
        end
      end
      exit
    end

    def update_widget(screen, widget_name, threaded=true)
      settings = @config["widgets"][screen][widget_name]
      begin
        @log.debug("Updating widget #{widget_name} of type #{settings["type"]} on screen #{screen}")
        update = Proc.new do
          widget = Widgets.const_get(settings["type"]).new(widget_name, settings)
          @awesome.widget_tell(screen, widget_name, widget.formatize)
        end
        if threaded
          Thread.new &update
        else
          update.call
        end
      rescue WidgetError => e
        @log.error(settings["type"]) { e.message }
      end
    end
  end
end
